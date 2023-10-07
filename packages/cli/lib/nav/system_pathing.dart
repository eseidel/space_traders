import 'package:cli/cache/caches.dart';
import 'package:cli/nav/route.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

int _approximateTimeBetween(
  SystemsCache systemsCache,
  System aSystem,
  SystemSymbol bSymbol,
  int shipSpeed,
) {
  final aSymbol = aSystem.systemSymbol;
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
  ConnectedSystem bSystem,
  int shipSpeed,
) {
  final distance = aSystem.position.distanceTo(bSystem.position);
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
  final frontier =
      PriorityQueue<(SystemSymbol, int)>((a, b) => a.$2.compareTo(b.$2))
        ..add((start.systemSymbol, 0));
  final cameFrom = <SystemSymbol, SystemSymbol>{};
  final costSoFar = <SystemSymbol, int>{};
  final startSymbol = start.systemSymbol;
  final endSymbol = end.systemSymbol;
  costSoFar[start.systemSymbol] = 0;
  while (frontier.isNotEmpty) {
    final current = frontier.removeFirst();
    if (current.$1 == endSymbol) {
      break;
    }
    final currentSystem = systemsCache.systemBySymbol(current.$1);
    for (final nextSystem in systemsCache.connectedSystems(current.$1)) {
      final next = nextSystem.systemSymbol;
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
