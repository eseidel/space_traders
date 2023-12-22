import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

// TODO(eseidel): I suspect we could delete this and use _timeBetween.
int _approximateTimeBetween(
  SystemWaypoint a,
  SystemWaypoint b,
  int shipSpeed,
  ShipNavFlightMode flightMode,
) {
  return _timeBetween(a, b, shipSpeed, flightMode);
}

int _timeBetween(
  SystemWaypoint a,
  SystemWaypoint b,
  int shipSpeed,
  ShipNavFlightMode flightMode,
) {
  return flightTimeWithinSystemInSeconds(
    a,
    b,
    shipSpeed: shipSpeed,
    flightMode: flightMode,
  );
}

/// Returns the path from [start] to [end] as a list of RouteActions.
/// Only works if [start] and [end] are in the same system.
/// This relies on sellFuel callback to determine if a waypoint sells fuel.
List<RouteAction>? findRouteWithinSystem(
  SystemsCache systemsCache, {
  required WaypointSymbol start,
  required WaypointSymbol end,
  required int shipSpeed,
  required int fuelCapacity,
  required bool Function(WaypointSymbol) sellsFuel,
}) {
  final startWaypoint = systemsCache.waypoint(start);
  final endWaypoint = systemsCache.waypoint(end);
  if (start.systemSymbol != end.systemSymbol) {
    throw ArgumentError(
      'Cannot find path between ${start.systemSymbol} and ${end.systemSymbol}',
    );
  }

  final startToEndDistance = startWaypoint.distanceTo(endWaypoint);
  final fuelUsedByDirectCruise =
      fuelUsedByDistance(startToEndDistance, ShipNavFlightMode.CRUISE);
  if (fuelUsedByDirectCruise <= fuelCapacity) {
    return [
      RouteAction(
        startSymbol: start,
        endSymbol: end,
        type: RouteActionType.navCruise,
        seconds: flightTimeWithinSystemInSeconds(
          startWaypoint,
          endWaypoint,
          shipSpeed: shipSpeed,
        ),
        fuelUsed: fuelUsedByDirectCruise,
      ),
    ];
  }

  final systemWaypoints = systemsCache.waypointsInSystem(start.systemSymbol);
  // We only consider waypoints that have markets that sell fuel.
  // Also include the start and end waypoints.
  final waypoints = systemWaypoints.where((w) {
    final symbol = w.waypointSymbol;
    return sellsFuel(symbol) || symbol == start || symbol == end;
  }).toList();

  ShipNavFlightMode flightModeRequired({
    required SystemWaypoint from,
    required SystemWaypoint to,
  }) {
    // Ships that don't use fuel can just always cruise.
    if (fuelCapacity == 0) {
      return ShipNavFlightMode.CRUISE;
    }
    // Careful, this assumes that CRUISE uses one fuel per distance unit.
    return from.distanceTo(to) <= fuelCapacity
        ? ShipNavFlightMode.CRUISE
        : ShipNavFlightMode.DRIFT;
  }

  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  // This code is hot enough that SystemSymbol.fromString shows up!
  final frontier =
      PriorityQueue<(WaypointSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start, 0));
  final cameFrom = <WaypointSymbol, RouteAction>{};
  final costSoFar = <WaypointSymbol, int>{};
  costSoFar[start] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    final currentSymbol = current.$1;
    if (currentSymbol == end) {
      break;
    }
    final currentWaypoint = systemsCache.waypoint(currentSymbol);
    // All waypoints are always reachable, just a question of what flight mode.
    for (final nextWaypoint in waypoints) {
      final flightMode =
          flightModeRequired(from: currentWaypoint, to: nextWaypoint);
      final next = nextWaypoint.waypointSymbol;
      final duration =
          _timeBetween(currentWaypoint, nextWaypoint, shipSpeed, flightMode);
      final newCost = costSoFar[currentSymbol]! + duration;
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost +
            _approximateTimeBetween(
              endWaypoint,
              nextWaypoint,
              shipSpeed,
              flightMode,
            );
        frontier.add((next, priority));
        final type = flightMode == ShipNavFlightMode.CRUISE
            ? RouteActionType.navCruise
            : RouteActionType.navDrift;
        final action = RouteAction(
          startSymbol: currentSymbol,
          endSymbol: nextWaypoint.waypointSymbol,
          type: type,
          seconds: duration,
          fuelUsed: fuelUsedByDistance(
            currentWaypoint.distanceTo(nextWaypoint),
            flightMode,
          ),
        );
        cameFrom[next] = action;
      }
    }
  }
  // We never found a path to end, so return null.
  if (cameFrom[end] == null) {
    return null;
  }

  final actions = <RouteAction>[];
  do {
    final action = cameFrom[end]!;
    actions.add(action);
    // Currently any visit to a non-start/non-end waypoint is to refuel.
    if (action.startSymbol != start && sellsFuel(action.startSymbol)) {
      actions.add(
        RouteAction(
          startSymbol: action.startSymbol,
          endSymbol: action.startSymbol,
          type: RouteActionType.refuel,
          seconds: 0,
          fuelUsed: 0,
        ),
      );
    }
    // Move to the next prior waypoint and continue.
    end = action.startSymbol;
  } while (cameFrom[end] != null);
  return actions.reversed.toList();
}
