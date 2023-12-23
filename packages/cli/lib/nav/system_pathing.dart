import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Returns the path from [start] to [end] as a list of system symbols.
List<SystemSymbol>? findSystemPath(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  System start,
  System end,
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

  const timeBetween = cooldownTimeForJumpBetweenSystems;
  // A* only requires approximate weights.  We could use real weights here
  // but we'd have to remove case which calls this function with the same
  // system (end, end) which will assert in cooldownTimeForJumpBetweenSystems.
  int approximateTimeBetween(System a, System b) => a.distanceTo(b);

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

    for (final nextSystem in connectedSystems) {
      final next = nextSystem.systemSymbol;
      // TODO(eseidel): work around a bug in directlyConnectedSystemSymbols.
      if (next == currentSymbol) {
        continue;
      }
      final newCost =
          costSoFar[currentSymbol]! + timeBetween(currentSystem, nextSystem);
      if (!costSoFar.containsKey(next) || newCost < costSoFar[next]!) {
        costSoFar[next] = newCost;
        final priority = newCost + approximateTimeBetween(end, nextSystem);
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
  SystemConnectivity systemConnectivity,
  WaypointSymbol start,
  WaypointSymbol end,
) {
  final startSystem = systemsCache.systemBySymbol(start.systemSymbol);
  final endSystem = systemsCache.systemBySymbol(end.systemSymbol);
  if (start.systemSymbol == end.systemSymbol) {
    // The caller needs to turn this into a real intra-system path.
    return [start, end];
  }
  if (!startSystem.hasJumpGate || !endSystem.hasJumpGate) {
    return null;
  }

  final systemSymbols = findSystemPath(
    systemsCache,
    systemConnectivity,
    startSystem,
    endSystem,
  );
  if (systemSymbols == null) {
    return null;
  }
  // TODO(eseidel): This will fail if systems have more than one jump gate.
  final jumpGateSymbols = systemSymbols
      .map((s) => systemsCache.jumpGateWaypointForSystem(s)!.waypointSymbol);
  return [
    if (start != jumpGateSymbols.first) start,
    ...jumpGateSymbols,
    if (end != jumpGateSymbols.last) end,
  ];
}
