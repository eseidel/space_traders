import 'package:cli/api.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:types/types.dart';

/// Begins a new nagivation action for [ship] to [destinationSymbol].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the destination to the ship's behavior state.
Future<DateTime?> beingNewRouteAndLog(
  Api api,
  Ship ship,
  BehaviorState state,
  ShipCache shipCache,
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  CentralCommand centralCommand,
  WaypointSymbol destinationSymbol,
) async {
  final start = ship.waypointSymbol;
  final route = routePlanner.planRoute(
    start: start,
    end: destinationSymbol,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (route == null) {
    shipErr(ship, 'No route to $destinationSymbol!?');
    return null;
  }
  final action = route.actions.firstOrNull;
  if (action == null) {
    // Was the caller supposed to check for this case and not ask to route?
    shipErr(
      ship,
      'No actions in route to $destinationSymbol from $start!?',
    );
    return null;
  }
  final waitTime = await beingRouteAndLog(
    api,
    ship,
    state,
    shipCache,
    systemsCache,
    centralCommand,
    route,
  );
  return waitTime;
}

/// Begins a new nagivation action [ship] along [routePlan].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the route to the ship's behavior state.
Future<DateTime?> beingRouteAndLog(
  Api api,
  Ship ship,
  BehaviorState state,
  ShipCache shipCache,
  SystemsCache systemsCache,
  CentralCommand centralCommand,
  RoutePlan routePlan,
) async {
  if (routePlan.actions.isEmpty) {
    shipWarn(ship, "Route plan is empty, assuming we're already there.");
    return null;
  }

  state.routePlan = routePlan;
  // TODO(eseidel): Should this buy fuel first if we need it?
  shipInfo(ship, 'Beginning route to ${routePlan.endSymbol}');
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    state,
    shipCache,
    systemsCache,
    centralCommand,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  return null;
}

enum _NavResultType {
  wait,
  continueAction,
  loop,
}

/// The result from continueNavigationIfNeeded
class NavResult {
  /// Wait tells the caller to return out the DateTime to have the ship
  /// wait.
  NavResult._wait(DateTime wait)
      : _type = _NavResultType.wait,
        _waitTime = wait;

  /// ContniueAction tells the caller it is OK to continue the action,
  /// we have done whatever navigation was necessary.
  NavResult._continueAction()
      : _type = _NavResultType.continueAction,
        _waitTime = null;

  /// Loop tells the caller to loop back to the top of the loop immediately.
  /// Typically this means returning null from the action.
  /// We likely need to do more navigation.
  NavResult._loop()
      : _type = _NavResultType.loop,
        _waitTime = null;

  final _NavResultType _type;
  final DateTime? _waitTime;

  /// Whether the caller should return after the navigation action
  bool shouldReturn() => _type != _NavResultType.continueAction;

  /// The wait time if [shouldReturn] is true
  DateTime? get waitTime {
    if (!shouldReturn()) {
      throw StateError('Cannot get wait time for non-wait result');
    }
    return _waitTime;
  }
}

void _verifyJumpTime(
  SystemsCache systemsCache,
  Ship ship,
  SystemSymbol fromSystem,
  SystemSymbol toSystem,
  Cooldown cooldown,
) {
  final from = systemsCache.systemBySymbol(fromSystem);
  final to = systemsCache.systemBySymbol(toSystem);
  final expectedCooldown = cooldownTimeForJumpBetweenSystems(from, to);
  final distance = from.distanceTo(to);
  final actualCooldown = cooldown.totalSeconds;
  if (expectedCooldown != actualCooldown) {
    shipWarn(
        ship,
        'Jump ${from.symbol} to ${to.symbol} ($distance) '
        'expected $expectedCooldown, got $actualCooldown.');
  }
}

/// Continue navigation if needed, returning the wait time if so.
/// Reads the destination from the ship's behavior state.
Future<NavResult> continueNavigationIfNeeded(
  Api api,
  Ship ship,
  BehaviorState state,
  ShipCache shipCache,
  SystemsCache systemsCache,
  CentralCommand centralCommand, {
  // Hook for overriding the current time in tests.
  DateTime Function() getNow = defaultGetNow,
}) async {
  // This can't work because nothing ever updates the ship to say it's not
  // in transit.  Either we need to speculatively update it ourselves, or
  // we need to refresh that part of the ship cache from the server.
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    final now = getNow();
    final waitUntil = logRemainingTransitTime(ship, getNow: getNow);
    if (!waitUntil.isBefore(now)) {
      return NavResult._wait(waitUntil);
    }
    // Otherwise fix the ship's state and continue;
    shipDetail(ship, 'Ship is in transit, but transit time is over');
    // This can race with the check in ship_cache.dart.  Since it might decide
    // that it's time to check our ships against the server and find that a ship
    // has arrived before we got a chance to update it here.
    ship.nav.status = ShipNavStatus.IN_ORBIT;
  }
  final routePlan = state.routePlan;
  if (routePlan == null) {
    // We don't have a routePlan, so we can't navigate.
    return NavResult._continueAction();
  }
  if (routePlan.actions.isEmpty) {
    shipWarn(ship, "Route plan is empty, assuming we're already there.");
    state.routePlan = null;
    return NavResult._continueAction();
  }

  // We've reached the routePlan, so we can stop navigating.
  if (ship.waypointSymbol == routePlan.endSymbol) {
    // Remove the destination from the ship's state or it will try to come back.
    state.routePlan = null;
    return NavResult._continueAction();
  }
  final action = routePlan.nextActionFrom(ship.waypointSymbol);
  final actionStart = systemsCache.waypointFromSymbol(action.startSymbol);
  final actionEnd = systemsCache.waypointFromSymbol(action.endSymbol);
  await undockIfNeeded(api, shipCache, ship);
  switch (action.type) {
    case RouteActionType.emptyRoute:
      shipWarn(ship, 'Empty route action, assuming we are already there.');
      return NavResult._continueAction();
    case RouteActionType.jump:
      final response =
          await useJumpGateAndLog(api, shipCache, ship, actionEnd.systemSymbol);
      _verifyJumpTime(
        systemsCache,
        ship,
        actionStart.systemSymbol,
        actionEnd.systemSymbol,
        response.cooldown,
      );
      // We don't return the cooldown time here because that would needlessly
      // delay the next action if the next action does not require a cooldown.
      final reactorCooloff = response.cooldown.expiration!;
      shipCache.setReactorCooldown(ship, reactorCooloff);
      final nextAction = routePlan.actionAfter(action);
      if (nextAction == null) {
        return NavResult._continueAction();
      }
      if (nextAction.usesReactor()) {
        // We need to wait for the reactor to cool down.
        return NavResult._wait(reactorCooloff);
      }
      // Otherwise loop immediately since we don't need to wait for the reactor.
      return NavResult._loop();
    case RouteActionType.navCruise:
      // We're in the same system as the end, so we can just navigate there.
      final arrivalTime =
          await navigateToLocalWaypointAndLog(api, shipCache, ship, actionEnd);
      final flightTime = arrivalTime.difference(DateTime.timestamp());

      final expectedFlightTime = Duration(
        seconds: flightTimeWithinSystemInSeconds(
          actionStart,
          actionEnd,
          shipSpeed: ship.engine.speed,
          flightMode: ship.nav.flightMode,
        ),
      );
      final delta = (flightTime - expectedFlightTime).inSeconds.abs();
      if (delta > 1) {
        shipWarn(
          ship,
          'Flight time ${durationString(flightTime)} '
          'does not match predicted ${durationString(expectedFlightTime)}',
        );
      }
      return NavResult._wait(arrivalTime);
  }
}
