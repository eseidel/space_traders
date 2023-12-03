import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Default implementation of sellsFuel for passing to routePlanner.
/// Returns a function which will return true if market at a given waypoint
/// symbol is known to sell fuel and false if we either don't know or
/// know it doesn't sell fuel.
bool Function(WaypointSymbol) defaultSellsFuel(MarketListingCache listings) {
  return (WaypointSymbol symbol) {
    final listing = listings.marketListingForSymbol(symbol);
    return listing?.allowsTradeOf(TradeSymbol.FUEL) ?? false;
  };
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

/// Begins a new nagivation action [ship] along [routePlan].
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
  final message = 'Beginning route to ${routePlan.endSymbol.sectorLocalName} '
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

enum _NavResultType {
  wait,
  continueAction,
  // loop,
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
  // NavResult._loop()
  //     : _type = _NavResultType.loop,
  //       _waitTime = null;

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

// void _verifyJumpTime(
//   SystemsCache systemsCache,
//   Ship ship,
//   SystemSymbol fromSystem,
//   SystemSymbol toSystem,
//   Cooldown cooldown,
// ) {
//   final from = systemsCache[fromSystem];
//   final to = systemsCache[toSystem];
//   final distance = from.distanceTo(to);
//   verifyCooldown(
//     ship,
//     'Jump ${from.symbol} to ${to.symbol} ($distance)',
//     cooldownTimeForJumpBetweenSystems(from, to),
//     cooldown,
//   );
// }

/// Exception thrown when navigation fails.
class NavigationException implements Exception {
  /// Create a new navigation exception.
  NavigationException(this.message);

  /// Message for this exception.
  final String message;

  @override
  String toString() => 'NavigationException: $message';
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
  if (action == null) {
    throw NavigationException('No action for ${ship.waypointSymbol} '
        'in route plan, likely off course.');
  }
  final actionEnd = caches.systems.waypoint(action.endSymbol);
  // All navigation actions require being un-docked, but the action functions
  // will handle that for us.
  switch (action.type) {
    case RouteActionType.emptyRoute:
      shipWarn(ship, 'Empty route action, assuming we are already there.');
      return NavResult._continueAction();
    case RouteActionType.jump:
      throw UnimplementedError('Jump not implemented');
    //   final response =
    //       await useJumpGateAndLog(api, shipCache,
    //           ship, actionEnd.systemSymbol);
    //   _verifyJumpTime(
    //     systemsCache,
    //     ship,
    //     actionStart.systemSymbol,
    //     actionEnd.systemSymbol,
    //     response.cooldown,
    //   );
    //   // We don't return the cooldown time here because that would needlessly
    //   // delay the next action if the next action does not require a cooldown.
    //   final nextAction = routePlan.actionAfter(action);
    //   if (nextAction == null) {
    //     return NavResult._continueAction();
    //   }
    //   if (nextAction.usesReactor) {
    //     // We need to wait for the reactor to cool down.
    //     // We know that ship.cooldown.expiration is non-null because it
    //     // was just set by useJumpGateAndLog.
    //     return NavResult._wait(ship.cooldown.expiration!);
    //   }
    //   // Otherwise loop immediately since we don't need to wait for the reactor.
    //   return NavResult._loop();
    case RouteActionType.refuel:
      final market = await visitLocalMarket(api, db, caches, ship);
      if (market == null) {
        shipErr(ship, 'No market at ${ship.waypointSymbol}, cannot refuel');
        return NavResult._continueAction();
      }
      await refuelIfNeededAndLog(
        api,
        db,
        caches.marketPrices,
        caches.agent,
        caches.ships,
        market,
        ship,
      );
      return NavResult._continueAction();
    case RouteActionType.navCruise:
      if (ship.usesFuel) {
        final fuelNeeded = action.fuelUsed;
        jobAssert(
          fuelNeeded < ship.fuel.capacity,
          'Planned navigation requires more fuel than ship can hold '
          '(${ship.fuel.capacity} < $fuelNeeded)',
          const Duration(minutes: 10),
        );
        if (fuelNeeded > ship.fuel.current) {
          final market = await visitLocalMarket(
            api,
            db,
            caches,
            ship,
          );
          if (market != null) {
            await refuelIfNeededAndLog(
              api,
              db,
              caches.marketPrices,
              caches.agent,
              caches.ships,
              market,
              ship,
            );
          } else {
            shipErr(
                ship,
                'No market at ${ship.waypointSymbol}, '
                'cannot refuel, drifting anyway');
          }
        }
      }
      return NavResult._wait(
        await navigateToLocalWaypointAndLog(
          api,
          caches.systems,
          caches.ships,
          ship,
          actionEnd,
        ),
      );
    case RouteActionType.navDrift:
      return NavResult._wait(
        await navigateToLocalWaypointAndLog(
          api,
          caches.systems,
          caches.ships,
          ship,
          actionEnd,
        ),
      );
  }
}
