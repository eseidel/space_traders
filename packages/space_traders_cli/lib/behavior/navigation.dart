import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

/// Begins a new nagivation action for [ship] to [destinationSymbol].
/// Returns the wait time if the ship should wait or null if no wait is needed.
/// Saves the destination to the ship's behavior state.
Future<DateTime?> beingRouteAndLog(
  Api api,
  Ship ship,
  WaypointCache waypointCache,
  BehaviorManager behaviorManager,
  String destinationSymbol,
) async {
  final state = await behaviorManager.getBehavior(ship.symbol);
  state.destination = destinationSymbol;
  // TODO(eseidel): Pass in the whole route and log it?
  shipInfo(ship, 'Begining route to $destinationSymbol');
  await behaviorManager.setBehavior(ship.symbol, state);
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    waypointCache,
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

/// Continue navigation if needed, returning the wait time if so.
/// Reads the destination from the ship's behavior state.
Future<NavResult> continueNavigationIfNeeded(
  Api api,
  Ship ship,
  WaypointCache waypointCache,
  BehaviorManager behaviorManager,
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return NavResult._wait(logRemainingTransitTime(ship));
  }
  final state = await behaviorManager.getBehavior(ship.symbol);
  final destinationSymbol = state.destination;
  if (destinationSymbol == null) {
    // We don't have a destination, so we can't navigate.
    return NavResult._continueAction();
  }
  // We've reached the destination, so we can stop navigating.
  if (ship.nav.waypointSymbol == destinationSymbol) {
    return NavResult._continueAction();
  }
  final endWaypoint = await waypointCache.waypoint(destinationSymbol);
  if (endWaypoint.systemSymbol == ship.nav.systemSymbol) {
    // We're in the same system as the end, so we can just navigate there.
    return NavResult._wait(
      await navigateToLocalWaypointAndLog(api, ship, endWaypoint),
    );
  }
  // Otherwise, jump to the next system most in its direction.
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  if (currentWaypoint.isJumpGate) {
    // We are at a jump gate, so we can jump to the next system.
    await useJumpGateAndLog(api, ship, endWaypoint.systemSymbol);
    // We can't continue the current action, we have more navigation to do
    // but it's better to figure that out from the top of the loop again.
    return NavResult._loop();
  }
  // We are not at a jump gate, so we need to navigate to the nearest one.
  final jumpGate = await waypointCache.jumpGateWaypointForSystem(
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
