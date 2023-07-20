import 'package:cli/cache/caches.dart';
import 'package:cli/nav/route.dart';
import 'package:collection/collection.dart';

typedef _WaypointSymbol = String;

Iterable<_WaypointSymbol> _neighborsFor(
  SystemsCache systemsCache,
  _WaypointSymbol symbol,
) sync* {
  final waypoint = systemsCache.waypointFromSymbol(symbol);
  // If we're currently at a jump gate, we can jump to any other jumpgate
  // connected to this one.
  if (waypoint.isJumpGate) {
    final systems = systemsCache.connectedSystems(waypoint.systemSymbol.system);
    for (final system in systems) {
      yield systemsCache.jumpGateWaypointForSystem(system.symbol)!.symbol;
    }
  }
  // Otherwise we can always navigate to any other waypoint in this system.
  // TODO(eseidel): This needs to enforce fuelCapacity.
  final otherWaypoints =
      systemsCache.waypointsInSystem(waypoint.systemSymbol.system);
  for (final otherWaypoint in otherWaypoints) {
    if (otherWaypoint.symbol != waypoint.symbol) {
      yield otherWaypoint.symbol;
    }
  }
  // We don't currently support warping.
}

int _approximateTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  _WaypointSymbol bSymbol,
  int shipSpeed,
) {
  if (a.symbol == bSymbol) {
    return 0;
  }
  final b = systemsCache.waypointFromSymbol(bSymbol);
  if (a.systemSymbol == b.systemSymbol) {
    return flightTimeWithinSystemInSeconds(a, b, shipSpeed: shipSpeed);
    // return a.position.distanceTo(b.position) ~/ shipSpeed;
  }
  final aSystem = systemsCache.systemBySymbol(a.systemSymbol.system);
  final aGate = aSystem.jumpGateWaypoint;
  if (aGate == null) {
    throw Exception('No jump gate in system ${a.systemSymbol}');
  }
  final bSystem = systemsCache.systemBySymbol(b.systemSymbol.system);
  final bGate = bSystem.jumpGateWaypoint;
  if (bGate == null) {
    throw Exception('No jump gate in system ${b.systemSymbol}');
  }
  final systemDistance = aSystem.distanceTo(bSystem);
  // final aTimeToGate = a.distanceTo(aGate) ~/ shipSpeed;
  // final bTimeToGate = b.distanceTo(bGate) ~/ shipSpeed;
  final aTimeToGate =
      flightTimeWithinSystemInSeconds(a, aGate, shipSpeed: shipSpeed);
  final bTimeToGate =
      flightTimeWithinSystemInSeconds(b, bGate, shipSpeed: shipSpeed);
  // Cooldown time for jumps is Math.max(60, distance / 10)
  // distance / 10 is an approximation of the cooldown time for a jump gate.
  // This assumes there are direct jumps in a line.
  return aTimeToGate + bTimeToGate + systemDistance ~/ 10;
}

int _timeBetween(
  SystemsCache systemsCache,
  _WaypointSymbol aSymbol,
  _WaypointSymbol bSymbol,
  int shipSpeed,
) {
  if (aSymbol == bSymbol) {
    return 0;
  }
  // TODO(eseidel): This should compute the exact travel time and likely
  // return a RouteAction.
  final a = systemsCache.waypointFromSymbol(aSymbol);
  final b = systemsCache.waypointFromSymbol(bSymbol);
  return _approximateTimeBetween(systemsCache, a, b.symbol, shipSpeed);
}

/// Returns the path from [start] to [end] as a list of waypoint symbols.
List<String>? findWaypointPath(
  SystemsCache systemsCache,
  SystemWaypoint start,
  SystemWaypoint end,
  int shipSpeed,
) {
  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  final frontier =
      PriorityQueue<(_WaypointSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start.symbol, 0));
  final cameFrom = <_WaypointSymbol, _WaypointSymbol>{};
  final costSoFar = <_WaypointSymbol, int>{};
  // logger.info('start: ${start.symbol} end: ${end.symbol}');
  costSoFar[start.symbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    // logger.info('current: ${current.$1}');
    if (current.$1 == end.symbol) {
      break;
    }
    for (final next in _neighborsFor(systemsCache, current.$1)) {
      // logger.info('considering: $next');
      final newCost = costSoFar[current.$1]! +
          _timeBetween(systemsCache, current.$1, next, shipSpeed);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost +
            _approximateTimeBetween(systemsCache, end, next, shipSpeed);
        frontier.add((next, priority));
        cameFrom[next] = current.$1;
      }
    }
  }
  if (cameFrom[end.symbol] == null) {
    return null;
  }

  final symbols = <_WaypointSymbol>[];
  var current = end.symbol;
  while (current != start.symbol) {
    symbols.add(current);
    current = cameFrom[current]!;
  }
  symbols.add(start.symbol);
  return symbols.reversed.toList();
}
