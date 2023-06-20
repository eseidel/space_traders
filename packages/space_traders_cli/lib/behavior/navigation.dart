import 'dart:math';

import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/printing.dart';

/// Begins a new nagivation action for [ship] to [destinationSymbol].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the destination to the ship's behavior state.
Future<DateTime?> beingRouteAndLog(
  Api api,
  Ship ship,
  SystemsCache systemsCache,
  BehaviorManager behaviorManager,
  String destinationSymbol,
) async {
  final state = await behaviorManager.getBehavior(ship);
  state.destination = destinationSymbol;
  // TODO(eseidel): Should this buy fuel first if we need it?
  shipInfo(ship, 'Begining route to $destinationSymbol');
  await behaviorManager.setBehavior(ship.symbol, state);
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    systemsCache,
    behaviorManager,
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

int _distanceBetweenConnectedSystems(ConnectedSystem a, System b) {
  // Use euclidean distance.
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy).round();
}

// int _distanceBetweenSystems(System a, System b) {
//   // Use euclidean distance.
//   final dx = a.x - b.x;
//   final dy = a.y - b.y;
//   return sqrt(dx * dx + dy * dy).round();
// }

/// Continue navigation if needed, returning the wait time if so.
/// Reads the destination from the ship's behavior state.
Future<NavResult> continueNavigationIfNeeded(
  Api api,
  Ship ship,
  SystemsCache systemsCache,
  BehaviorManager behaviorManager, {
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
  final state = await behaviorManager.getBehavior(ship);
  final destinationSymbol = state.destination;
  if (destinationSymbol == null) {
    // We don't have a destination, so we can't navigate.
    return NavResult._continueAction();
  }
  // We've reached the destination, so we can stop navigating.
  if (ship.nav.waypointSymbol == destinationSymbol) {
    // Remove the destination from the ship's state or it will try to come back.
    state.destination = null;
    await behaviorManager.setBehavior(ship.symbol, state);
    return NavResult._continueAction();
  }
  final endWaypoint = systemsCache.waypointFromSymbol(destinationSymbol);
  if (endWaypoint.systemSymbol == ship.nav.systemSymbol) {
    // We're in the same system as the end, so we can just navigate there.
    return NavResult._wait(
      await navigateToLocalWaypointAndLog(api, ship, endWaypoint),
    );
  }
  // Otherwise, jump to the next system most in its direction.
  final currentWaypoint =
      systemsCache.waypointFromSymbol(ship.nav.waypointSymbol);
  if (currentWaypoint.isJumpGate) {
    // Check to make sure the system isn't out of range.  If it is, we need
    // to jump to a system along the way.
    final connectedSystems =
        systemsCache.connectedSystems(currentWaypoint.systemSymbol);
    if (connectedSystems.any((s) => s.symbol == endWaypoint.systemSymbol)) {
      // We can jump directly to the end system.
      await useJumpGateAndLog(api, ship, endWaypoint.systemSymbol);
      // We can't continue the current action, we have more navigation to do
      // but it's better to figure that out from the top of the loop again.
      return NavResult._loop();
    }
    // Otherwise we have to jump to a system along the way.
    final endSystem = systemsCache.systemBySymbol(endWaypoint.systemSymbol);
    final closestSystem = connectedSystems.reduce(
      (a, b) => _distanceBetweenConnectedSystems(a, endSystem) <
              _distanceBetweenConnectedSystems(b, endSystem)
          ? a
          : b,
    );
    // What if the closest system is further than the one we're already in?
    final response = await useJumpGateAndLog(api, ship, closestSystem.symbol);
    // We will have to jump again, so just wait at the jump gate.
    return NavResult._wait(response.cooldown.expiration!);
  }
  // We are not at a jump gate, so we need to navigate to the nearest one.
  final jumpGate = systemsCache.jumpGateWaypointForSystem(
    currentWaypoint.systemSymbol,
  );
  if (jumpGate == null) {
    throw StateError(
      'No jump gate found for system ${currentWaypoint.systemSymbol}',
    );
  }
  return NavResult._wait(
    await navigateToLocalWaypointAndLog(api, ship, jumpGate),
  );
}
