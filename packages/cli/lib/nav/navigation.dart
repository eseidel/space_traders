import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Extensions on Ship to help with navigation.
extension ShipNavUtils on Ship {
  /// How long until we arrive at the given routePlan.
  Duration timeToArrival(
    RoutePlan routePlan, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final now = getNow();
    var timeLeft = nav.status == ShipNavStatus.IN_TRANSIT
        ? nav.route.arrival.difference(now)
        : Duration.zero;
    if (routePlan.endSymbol != waypointSymbol) {
      final newPlan = routePlan.subPlanStartingFrom(waypointSymbol);
      timeLeft += newPlan.duration;
      // Include cooldown until next jump.
      // We would need to keep ship cooldowns on ShipCache to do this.
      if (newPlan.actions.first.type == RouteActionType.jump) {
        final remaining = remainingCooldown(now) ?? Duration.zero;
        timeLeft += remaining;
      }
    }
    return timeLeft;
  }
}

/// Default implementation of sellsFuel for passing to routePlanner.
/// Returns a function which will return true if market at a given waypoint
/// symbol is known to sell fuel and false if we either don't know or
/// know it doesn't sell fuel.
Future<bool Function(WaypointSymbol)> defaultSellsFuel(Database db) async {
  final fuelMarkets = await db.marketListings.marketsSellingFuel();
  return fuelMarkets.contains;
}

/// Begins a new navigation action for [ship] to [destinationSymbol].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the destination to the ship's behavior state.
Future<DateTime?> beingNewRouteAndLog(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  WaypointSymbol destinationSymbol,
) async {
  final start = ship.waypointSymbol;
  final route = caches.routePlanner.planRoute(
    ship.shipSpec,
    start: start,
    end: destinationSymbol,
  );
  if (route == null) {
    throw JobException(
      'No route from $start to $destinationSymbol!?',
      const Duration(minutes: 10),
    );
  }
  final action = route.actions.firstOrNull;
  if (action == null) {
    // Was the caller supposed to check for this case and not ask to route?
    throw JobException(
      'No actions in route to $destinationSymbol from $start!?',
      const Duration(minutes: 10),
    );
  }
  if (route.actions.length > 1) {
    shipInfo(ship, 'Starting: ${describeRoutePlan(route)}');
  }
  final waitTime = await beingRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    route,
  );
  return waitTime;
}

/// Begins a new navigation action [ship] along [routePlan].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the route to the ship's behavior state.
Future<DateTime?> beingRouteAndLog(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  RoutePlan routePlan,
) async {
  if (routePlan.actions.isEmpty) {
    shipWarn(ship, "Route plan is empty, assuming we're already there.");
    return null;
  }

  state.routePlan = routePlan;
  final message =
      'Beginning route to ${routePlan.endSymbol.sectorLocalName} '
      '(${approximateDuration(routePlan.duration)})';
  if (routePlan.duration.inMinutes > 5) {
    shipWarn(ship, message);
  } else {
    shipInfo(ship, message);
  }
  final navResult = await continueNavigationIfNeeded(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  return null;
}

enum _NavResultType { wait, continueAction, loop }

/// The result from continueNavigationIfNeeded
class NavResult {
  /// Wait tells the caller to return out the DateTime to have the ship
  /// wait.
  NavResult._wait(DateTime wait)
    : _type = _NavResultType.wait,
      _waitTime = wait;

  /// ContinueAction tells the caller it is OK to continue the action,
  /// we have done whatever navigation was necessary.
  NavResult._continueAction()
    : _type = _NavResultType.continueAction,
      _waitTime = null;

  /// Loop tells the caller to loop back to the top of the loop immediately.
  /// Typically this means returning null from the action.
  /// We likely need to do more navigation.
  NavResult._loop() : _type = _NavResultType.loop, _waitTime = null;

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
  Ship ship,
  SystemRecord from,
  SystemRecord to,
  Cooldown cooldown,
) {
  final distance = from.distanceTo(to);
  verifyCooldown(
    ship,
    'Jump ${from.symbol} to ${to.symbol} ($distance)',
    cooldownTimeForJumpBetweenSystems(from, to),
    cooldown,
  );
}

/// Continue navigation if needed, returning the wait time if so.
/// Reads the destination from the ship's behavior state.
Future<NavResult> continueNavigationIfNeeded(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state, {
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
    // We don't have a routePlan, so we can't navigate. This is the common
    // case where continueNavigationIfNeeded isn't needed.
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
  if (action == null) {
    throw JobException(
      'No action for ${ship.waypointSymbol} '
      'in route plan, likely off course.',
      const Duration(minutes: 5),
    );
  }
  // jobAssert(
  //   ship.engine.condition > 0,
  //   'Engine is broken',
  //   const Duration(hours: 1),
  // );

  final actionEnd = caches.systems.waypoint(action.endSymbol);
  // All navigation actions require being un-docked, but the action functions
  // will handle that for us.
  switch (action.type) {
    case RouteActionType.emptyRoute:
      shipWarn(ship, 'Empty route action, assuming we are already there.');
      return NavResult._continueAction();
    case RouteActionType.jump:
      final JumpShip200ResponseData response;
      try {
        response = await useJumpGateAndLog(
          api,
          db,
          ship,
          actionEnd.symbol,
          medianAntimatterPrice: centralCommand.medianAntimatterPurchasePrice,
        );
      } on ApiException catch (e) {
        if (!isInsufficientCreditsException(e)) {
          rethrow;
        }
        throw const JobException(
          'Purchase of antimatter failed. Insufficient credits.',
          Duration(minutes: 60),
        );
      }

      _verifyJumpTime(
        ship,
        caches.systems.systemRecordBySymbol(action.startSymbol.system),
        caches.systems.systemRecordBySymbol(action.endSymbol.system),
        response.cooldown,
      );
      // We don't return the cooldown time here because that would needlessly
      // delay the next action if the next action does not require a cooldown.
      final nextAction = routePlan.actionAfter(action);
      if (nextAction == null) {
        return NavResult._continueAction();
      }
      if (nextAction.usesReactor) {
        // We need to wait for the reactor to cool down.
        // We know that ship.cooldown.expiration is non-null because it
        // was just set by useJumpGateAndLog.
        return NavResult._wait(ship.cooldown.expiration!);
      }
      // Otherwise loop immediately since we don't need to wait for the reactor.
      return NavResult._loop();
    case RouteActionType.refuel:
      final market = await visitLocalMarket(api, db, caches, ship);
      if (market == null) {
        shipErr(ship, 'No market at ${ship.waypointSymbol}, cannot refuel');
        return NavResult._continueAction();
      }
      await refuelIfNeededAndLog(
        api,
        db,
        market,
        ship,
        medianFuelPurchasePrice: centralCommand.medianFuelPurchasePrice,
      );
      // TODO(eseidel): This should be loop, but that can't work because we
      // can't figure out which action to do next when we do multiple actions
      // at the same waypoint.
      return NavResult._continueAction();
    case RouteActionType.navCruise:
      if (ship.usesFuel) {
        final fuelNeeded = action.fuelUsed;
        jobAssert(
          fuelNeeded <= ship.fuel.capacity,
          'Planned navigation from ${action.startSymbol} '
          'to ${action.endSymbol} requires more fuel than ${ship.symbol} '
          'can hold (${ship.fuel.capacity} < $fuelNeeded)',
          const Duration(minutes: 5),
        );
        if (fuelNeeded > ship.fuel.current) {
          final market = await visitLocalMarket(api, db, caches, ship);
          if (market != null) {
            await refuelIfNeededAndLog(
              api,
              db,
              market,
              ship,
              medianFuelPurchasePrice: centralCommand.medianFuelPurchasePrice,
            );
          } else {
            // TODO(eseidel): Make this throw once we're better about fuel.
            shipErr(
              ship,
              'No market at ${ship.waypointSymbol}, '
              'cannot refuel, need to replan.',
            );
            // throw JobException(
            //   'No market at ${ship.waypointSymbol}, '
            //   'cannot refuel, need to replan.',
            //   const Duration(minutes: 5),
            // );
          }
        }
      }
      final DateTime waitUntil;
      try {
        waitUntil = await navigateToLocalWaypointAndLog(
          db,
          api,
          caches.systems,
          ship,
          actionEnd,
        );
      } on ApiException catch (e) {
        if (isShipInTransitException(e)) {
          shipErr(ship, 'Ship is in transit, cannot navigate');
          throw const JobException(
            'Already in transit!?',
            Duration(minutes: 10),
          );
        }
        rethrow;
      }
      return NavResult._wait(waitUntil);
    case RouteActionType.navDrift:
      return NavResult._wait(
        await navigateToLocalWaypointAndLog(
          db,
          api,
          caches.systems,
          ship,
          actionEnd,
        ),
      );
    case RouteActionType.warpCruise:
      shipErr(ship, 'Warping to ${actionEnd.symbol}!');
      try {
        return NavResult._wait(
          await warpToWaypointAndLog(db, api, ship, actionEnd),
        );
      } on ApiException catch (e) {
        if (isInsufficientFuelException(e)) {
          throw const JobException('Not enough fuel', Duration(minutes: 10));
        }
        rethrow;
      }
  }
}
