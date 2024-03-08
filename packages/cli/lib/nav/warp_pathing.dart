import 'package:cli/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

// A direct jump between systems is always faster than warping if we're at
// the jump gate.
// Jump cooldown is 60 + systemDistance.round()
// Warp time is dist * (50 / speed) + 15
// Since the only warp capable ship is 30 speed, that's 50 / 30 = 1.6666
// So, warp time is 1.6666 * dist + 15

enum _ActionType {
  jump,
  warp,
}

// Used for planning the route, converted into RouteAction before returning.
class _SystemAction {
  _SystemAction({
    required this.startSymbol,
    required this.endSymbol,
    required this.type,
    required this.seconds,
    required this.fuelUsed,
  });
  final SystemSymbol startSymbol;
  final SystemSymbol endSymbol;
  final _ActionType type;
  final int seconds;
  final int fuelUsed;
}

/// Returns the path from [start] to [end] as a list of system symbols.
List<_SystemAction>? _findActionsBetweenSystems(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  ShipSpec shipSpec, {
  required SystemSymbol startSymbol,
  required SystemSymbol endSymbol,
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final end = systemsCache[endSymbol];
  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  // This code is hot enough that SystemSymbol.fromString shows up!
  final frontier =
      PriorityQueue<(SystemSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((startSymbol, 0));
  final cameFrom = <SystemSymbol, _SystemAction>{};
  final costSoFar = <SystemSymbol, int>{};
  costSoFar[startSymbol] = 0;

  // A* only requires approximate weights.  We could use real weights here
  // but we'd have to remove case which calls this function with the same
  // system (end, end) which will assert in cooldownTimeForJumpBetweenSystems.
  int approximateTimeBetween(System a, System b) => a.distanceTo(b).round();

  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    final currentSymbol = current.$1;
    if (currentSymbol == endSymbol) {
      break;
    }
    final currentSystem = systemsCache.systemBySymbol(currentSymbol);
    final connected =
        systemConnectivity.directlyConnectedSystemSymbols(currentSymbol);
    final connectedSystems = connected.map(systemsCache.systemBySymbol);

    const jumpTimeBetween = cooldownTimeForJumpBetweenSystems;

    // Add all the direct jumps.
    for (final nextSystem in connectedSystems) {
      final next = nextSystem.symbol;
      // TODO(eseidel): directlyConnectedSystemSymbols should not return
      // the start system, but it does.
      if (next == currentSymbol) {
        continue;
      }
      final newCost = costSoFar[currentSymbol]! +
          jumpTimeBetween(currentSystem, nextSystem);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost + approximateTimeBetween(end, nextSystem);
        frontier.add((next, priority));
        final action = _SystemAction(
          startSymbol: currentSymbol,
          endSymbol: next,
          type: _ActionType.jump,
          seconds: jumpTimeBetween(currentSystem, nextSystem),
          fuelUsed: 0,
        );
        cameFrom[next] = action;
      }
    }

    if (!shipSpec.canWarp) {
      continue;
    }
    // Add all possible warps.
    const flightMode = ShipNavFlightMode.CRUISE;
    int warpTimeBetween(System a, System b) {
      // Flight mode is implicitly CRUISE for warps currently.
      return warpTimeInSeconds(a, b, shipSpeed: shipSpec.speed);
    }

    final nearbySystems = systemsCache.systems.where(
      (s) =>
          s.symbol != currentSymbol &&
          s.distanceTo(currentSystem) < shipSpec.fuelCapacity,
    );
    for (final nextSystem in nearbySystems) {
      final next = nextSystem.symbol;
      // Ignore our start system.
      if (next == currentSymbol) {
        continue;
      }
      final newCost = costSoFar[currentSymbol]! +
          warpTimeBetween(currentSystem, nextSystem);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost + approximateTimeBetween(end, nextSystem);
        frontier.add((next, priority));
        final distance = currentSystem.distanceTo(nextSystem);
        final action = _SystemAction(
          startSymbol: currentSymbol,
          endSymbol: next,
          type: _ActionType.warp,
          seconds: warpTimeBetween(currentSystem, nextSystem),
          fuelUsed: fuelUsedByDistance(distance, flightMode),
        );
        cameFrom[next] = action;
      }
    }
  }
  if (cameFrom[endSymbol] == null) {
    return null;
  }

  final actions = <_SystemAction>[];
  var current = endSymbol;
  while (current != startSymbol) {
    final action = cameFrom[current]!;
    actions.add(action);
    current = action.endSymbol;
  }
  return actions.reversed.toList();
}

// We do our planning in terms of system symbols, but we need to return
// RouteActions which are in terms of waypoints.  For Warps, we just pick
// something with a market.  For Jumps those use JumpGates.
WaypointSymbol _waypointForSystem(
  SystemsCache systemsCache,
  SystemSymbol symbol,
) {
  final system = systemsCache.systemBySymbol(symbol);
  return system.jumpGateWaypoints.first.symbol;
}

/// Returns the route between [start] and [end] as a list of RouteActions.
/// Returns null if no route is possible.
/// The route will be planned for the given [shipSpec] and will include warps
/// if shipSpec.canWarp is true.
List<RouteAction>? findRouteBetweenSystems(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  ShipSpec shipSpec, {
  required WaypointSymbol start,
  required WaypointSymbol end,
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final systemActions = _findActionsBetweenSystems(
    systemsCache,
    systemConnectivity,
    shipSpec,
    startSymbol: start.system,
    endSymbol: end.system,
    sellsFuel: sellsFuel,
  );
  if (systemActions == null) {
    return null;
  }
  final routeActions = <RouteAction>[];
  for (final action in systemActions) {
    // TODO(eseidel): Fix this to have the right start/end symbols.
    routeActions.add(
      RouteAction(
        startSymbol: _waypointForSystem(systemsCache, action.startSymbol),
        endSymbol: _waypointForSystem(systemsCache, action.endSymbol),
        type: action.type == _ActionType.jump
            ? RouteActionType.jump
            : RouteActionType.warpCruise,
        seconds: action.seconds,
        fuelUsed: action.fuelUsed,
      ),
    );
  }
  return routeActions;
}
