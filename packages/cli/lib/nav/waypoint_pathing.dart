import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

// TODO(eseidel): I suspect we could delete this and use _timeBetween.
int _approximateTimeBetween(
  SystemWaypoint a,
  SystemWaypoint b,
  int shipSpeed,
) {
  return flightTimeWithinSystemInSeconds(
    a,
    b,
    shipSpeed: shipSpeed,
  );
}

int _timeBetween(
  SystemWaypoint a,
  SystemWaypoint b,
  int shipSpeed,
  int fuelCapacity,
) {
  final distance = a.position.distanceTo(b.position);
  assert(
    distance <= fuelCapacity,
    'Distance between ${a.symbol} and ${b.symbol} is $distance',
  );
  return flightTimeWithinSystemInSeconds(
    a,
    b,
    shipSpeed: shipSpeed,
  );
}

/// Returns the path from [start] to [end] as a list of waypoint symbols.
/// Only works if [start] and [end] are in the same system.
Future<List<WaypointSymbol>?> findWaypointPathWithinSystem(
  SystemsCache systemsCache,
  MarketCache marketCache,
  WaypointSymbol start,
  WaypointSymbol end,
  int shipSpeed,
  int fuelCapacity,
) async {
  final startWaypoint = systemsCache.waypointFromSymbol(start);
  final endWaypoint = systemsCache.waypointFromSymbol(end);
  if (start.systemSymbol != end.systemSymbol) {
    throw ArgumentError(
      'Cannot find path between ${start.systemSymbol} and ${end.systemSymbol}',
    );
  }

  if (startWaypoint.distanceTo(endWaypoint) <= fuelCapacity) {
    return [start, end];
  }

  final system = systemsCache.systemBySymbol(start.systemSymbol);
  // We only consider waypoints that have markets that sell fuel.
  // Also include the start and end waypoints.
  final waypoints = <SystemWaypoint>[];
  for (final waypoint in system.waypoints) {
    if (waypoint.waypointSymbol == start || waypoint.waypointSymbol == end) {
      waypoints.add(waypoint);
    }
    final market = await marketCache.marketForSymbol(waypoint.waypointSymbol);
    if (market != null && market.allowsTradeOf(TradeSymbol.FUEL)) {
      waypoints.add(waypoint);
    }
  }
  List<SystemWaypoint> reachableFrom(SystemWaypoint waypoint) {
    return waypoints.where((w) {
      final distance = waypoint.position.distanceTo(w.position);
      return distance <= fuelCapacity;
    }).toList();
  }

  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  // This code is hot enough that SystemSymbol.fromString shows up!
  final frontier =
      PriorityQueue<(WaypointSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start, 0));
  final cameFrom = <WaypointSymbol, WaypointSymbol>{};
  final costSoFar = <WaypointSymbol, int>{};
  costSoFar[start] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    final currentSymbol = current.$1;
    if (currentSymbol == end) {
      break;
    }
    final currentWaypoint = systemsCache.waypointFromSymbol(currentSymbol);
    final reachable = reachableFrom(currentWaypoint);
    for (final nextWaypoint in reachable) {
      final next = nextWaypoint.waypointSymbol;
      final newCost = costSoFar[currentSymbol]! +
          _timeBetween(currentWaypoint, nextWaypoint, shipSpeed, fuelCapacity);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost +
            _approximateTimeBetween(endWaypoint, nextWaypoint, shipSpeed);
        frontier.add((next, priority));
        cameFrom[next] = currentSymbol;
      }
    }
  }
  // We never found a path to end, so return null.
  if (cameFrom[end] == null) {
    return null;
  }

  final symbols = <WaypointSymbol>[];
  var current = end;
  while (current != start) {
    symbols.add(current);
    current = cameFrom[current]!;
  }
  symbols.add(start);
  return symbols.reversed.toList();
}
