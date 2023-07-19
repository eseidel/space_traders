import 'package:cli/cache/caches.dart';
import 'package:cli/nav/route.dart';
import 'package:collection/collection.dart';

typedef _SystemSymbol = String;

Iterable<System> _neighborsFor(
  SystemsCache systemsCache,
  System startSystem,
) sync* {
  final systemSymbol = startSystem.symbol;
  assert(startSystem.hasJumpGate, 'System $systemSymbol has no jump gate');
  final systems = systemsCache.connectedSystems(systemSymbol);
  for (final system in systems) {
    // Could also write a ConnectedSystem.toSystem() method.
    yield systemsCache.systemBySymbol(system.symbol);
  }
}

int _approximateTimeBetween(
  SystemsCache systemsCache,
  System aSystem,
  _SystemSymbol bSymbol,
  int shipSpeed,
) {
  final aSymbol = aSystem.symbol;
  if (aSymbol == bSymbol) {
    return 0;
  }
  final bSystem = systemsCache.systemBySymbol(bSymbol);
  assert(aSystem.hasJumpGate, 'System $aSymbol has no jump gate');
  assert(bSystem.hasJumpGate, 'System $bSymbol has no jump gate');
  final systemDistance = aSystem.distanceTo(bSystem);
  // Cooldown time for jumps is Math.max(60, distance / 10)
  // distance / 10 is an approximation of the cooldown time for a jump gate.
  // This assumes there are direct jumps in a line.
  return systemDistance ~/ 10;
}

int _timeBetween(
  SystemsCache systemsCache,
  System aSystem,
  System bSystem,
  int shipSpeed,
) {
  final distance = aSystem.distanceTo(bSystem);
  assert(
    distance <= 2000,
    'Distance between ${aSystem.symbol} and ${bSystem.symbol} is $distance',
  );
  return cooldownTimeForJumpDistance(distance);
}

/// Returns the path from [start] to [end] as a list of system symbols.
List<String>? findSystemPath(
  SystemsCache systemsCache,
  System start,
  System end,
  int shipSpeed,
) {
  // This is A* search, thanks to
  // https://www.redblobgames.com/pathfinding/a-star/introduction.html
  final frontier =
      PriorityQueue<(_SystemSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start.symbol, 0));
  final cameFrom = <_SystemSymbol, _SystemSymbol>{};
  final costSoFar = <_SystemSymbol, int>{};
  costSoFar[start.symbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    if (current.$1 == end.symbol) {
      break;
    }
    final currentSystem = systemsCache.systemBySymbol(current.$1);
    for (final nextSystem in _neighborsFor(systemsCache, currentSystem)) {
      final next = nextSystem.symbol;
      final newCost = costSoFar[current.$1]! +
          _timeBetween(systemsCache, currentSystem, nextSystem, shipSpeed);
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

  final symbols = <_SystemSymbol>[];
  var current = end.symbol;
  while (current != start.symbol) {
    symbols.add(current);
    current = cameFrom[current]!;
  }
  symbols.add(start.symbol);
  return symbols.reversed.toList();
}

/// Returns the path from [start] to [end] as a list of waypoint symbols.
List<String>? findWaypointPathJumpsOnly(
  SystemsCache systemsCache,
  SystemWaypoint start,
  SystemWaypoint end,
  int shipSpeed,
) {
  final startSystem = systemsCache.systemBySymbol(start.systemSymbol);
  final endSystem = systemsCache.systemBySymbol(end.systemSymbol);
  if (start.systemSymbol == end.systemSymbol) {
    return [start.symbol, end.symbol];
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
      .map((s) => systemsCache.jumpGateWaypointForSystem(s)!.symbol);
  return [
    if (start.symbol != jumpGateSymbols.first) start.symbol,
    ...jumpGateSymbols,
    if (end.symbol != jumpGateSymbols.last) end.symbol,
  ];
}
