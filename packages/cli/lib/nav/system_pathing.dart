import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

int _distanceBetween(System a, ConnectedSystem b) {
  return a.position.distanceTo(b.position);
}

// TODO(eseidel): I suspect we could delete this and use _timeBetween.
int _approximateTimeBetween(
  System aSystem,
  ConnectedSystem bSystem,
  int shipSpeed,
) {
  if (aSystem.symbol == bSystem.symbol) {
    return 0;
  }
  assert(aSystem.hasJumpGate, 'System ${aSystem.symbol} has no jump gate');
  // Cooldown time for jumps is Math.max(60, distance / 10)
  // distance / 10 is an approximation of the cooldown time for a jump gate.
  // This assumes there are direct jumps in a line.
  return _distanceBetween(aSystem, bSystem) ~/ 10;
}

int _timeBetween(
  System aSystem,
  ConnectedSystem bSystem,
  int shipSpeed,
) {
  final distance = _distanceBetween(aSystem, bSystem);
  assert(
    distance <= kJumpGateRange,
    'Distance between ${aSystem.symbol} and ${bSystem.symbol} is $distance',
  );
  return cooldownTimeForJumpDistance(distance);
}

/// Returns the path from [start] to [end] as a list of system symbols.
List<SystemSymbol>? findSystemPath(
  SystemsCache systemsCache,
  System start,
  System end,
  int shipSpeed,
) {
  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  // This code is hot enough that SystemSymbol.fromString shows up!
  final startSymbol = start.systemSymbol;
  final endSymbol = end.systemSymbol;
  final frontier =
      PriorityQueue<(SystemSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((startSymbol, 0));
  final cameFrom = <SystemSymbol, SystemSymbol>{};
  final costSoFar = <SystemSymbol, int>{};
  costSoFar[startSymbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    final currentSymbol = current.$1;
    if (currentSymbol == endSymbol) {
      break;
    }
    final currentSystem = systemsCache.systemBySymbol(currentSymbol);
    for (final nextSystem in systemsCache.connectedSystems(currentSymbol)) {
      final next = nextSystem.systemSymbol;
      final newCost = costSoFar[currentSymbol]! +
          _timeBetween(currentSystem, nextSystem, shipSpeed);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority =
            newCost + _approximateTimeBetween(end, nextSystem, shipSpeed);
        frontier.add((next, priority));
        cameFrom[next] = currentSymbol;
      }
    }
  }
  if (cameFrom[endSymbol] == null) {
    return null;
  }

  final symbols = <SystemSymbol>[];
  var current = endSymbol;
  while (current != startSymbol) {
    symbols.add(current);
    current = cameFrom[current]!;
  }
  symbols.add(startSymbol);
  return symbols.reversed.toList();
}

/// Returns the path from [start] to [end] as a list of waypoint symbols.
List<WaypointSymbol>? findWaypointPathJumpsOnly(
  SystemsCache systemsCache,
  WaypointSymbol start,
  WaypointSymbol end,
  int shipSpeed,
) {
  final startSystem = systemsCache.systemBySymbol(start.systemSymbol);
  final endSystem = systemsCache.systemBySymbol(end.systemSymbol);
  if (start.systemSymbol == end.systemSymbol) {
    return [start, end];
  }
  if (!startSystem.hasJumpGate || !endSystem.hasJumpGate) {
    return null;
  }

  final systemSymbols =
      findSystemPath(systemsCache, startSystem, endSystem, shipSpeed);
  if (systemSymbols == null) {
    return null;
  }
  final jumpGateSymbols = systemSymbols
      .map((s) => systemsCache.jumpGateWaypointForSystem(s)!.waypointSymbol);
  return [
    if (start != jumpGateSymbols.first) start,
    ...jumpGateSymbols,
    if (end != jumpGateSymbols.last) end,
  ];
}
