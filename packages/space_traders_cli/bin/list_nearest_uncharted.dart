import 'dart:core';

// Future<List<String>?> _innerRouteToNearestUnchartedWaypoint(
//   Api api,
//   Set<String> consideredSystems,
//   String waypointSymbol,
// ) async {
//   final systemWaypoints =
//  await waypointsInSystem(api, currentSystem).toList();
//   final currentWaypoint = lookupWaypoint(waypointSymbol, systemWaypoints);

//   final potentialRoutes = <(Waypoint, List<String>)>[
//     (currentWaypoint, [waypointSymbol])
//   ];

//   while (potentialRoutes.isNotEmpty) {
//     final (waypoint, route) = potentialRoutes.removeAt(0);
//     final currentSystem = parseWaypointString(waypointSymbol).system;
//     consideredSystems.add(waypoint.system);
//     for node in
//   }

//  queue = [(start,[start])]
// visited = set()

// while queue:
//     vertex, path = queue.pop(0)
//     visited.add(vertex)
//     for node in graph[vertex]:
//         if node == end:
//             return path + [end]
//         else:
//             if node not in visited:
//                 visited.add(node)
//                 queue.append((node, path + [node]))

// Check our current system first.
// If it has an uncharted waypoint, return closest?
// final unchartedWaypoints = systemWaypoints
//     .where((w) => w.type != WaypointType.JUMP_GATE && w.chart == null)
//     .toList();
// if (unchartedWaypoints.isNotEmpty) {
//   final sorted =
//       unchartedWaypoints.sortedBy<num>((w) => w.distanceTo(currentWaypoint));
//   return [sorted.first.symbol];
// }
// If it does not, we check what systems are connected via jumpgate
// Starting at the closest one, we check if it has an unexplored waypoint.
// If none of those do, we look at second jump potentials from the original
// list and repeat the process.

// See if any of these are unexplored.

//  1  procedure BFS(G, root) is
//  2      let Q be a queue
//  3      label root as explored
//  4      Q.enqueue(root)
//  5      while Q is not empty do
//  6          v := Q.dequeue()
//  7          if v is the goal then
//  8              return v
//  9          for all edges from v to w in G.adjacentEdges(v) do
// 10              if w is not labeled as explored then
// 11                  label w as explored
// 12                  w.parent := v
// 13                  Q.enqueue(w)

//   final jumpGateWaypoint =
//       systemWaypoints
//  .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);
//   final jumpGateResponse =
//       await api.systems.getJumpGate(currentSystem, jumpGateWaypoint!.symbol);
//   final jumpGate = jumpGateResponse!.data;
//   final connectedSystems = jumpGate.connectedSystems
//       .where((s) => !consideredSystems.contains(s.symbol))
//       .sortedBy<num>((s) => s.distance)
//       .toList();
//   for (final system in connectedSystems) {
//     logger.info('${system.symbol} - ${system.distance}');
//     final waypoints = await waypointsInSystem(api, system.symbol).toList();
//     printWaypoints(waypoints, indent: '  ');
//   }
//   return null;
// }

// Future<Route?> _routeToNearestUnchartedWaypoint(
//   Api api,
//   String waypointSymbol,
// ) async {
//   final consideredSystems = <String>{};
//   final routeSymbols = await _innerRouteToNearestUnchartedWaypoint(
//     api,
//     consideredSystems,
//     waypointSymbol,
//   );
//   if (routeSymbols == null) {
//     return null;
//   }
//   return Route(routeSymbols);
// }

// void main(List<String> args) async {
//   const fs = LocalFileSystem();
//   final api = defaultApi(fs);

//   final agentResult = await api.agents.getMyAgent();

//   final agent = agentResult!.data;
//   final hq = parseWaypointString(agent.headquarters);
//   final systemWaypoints = await waypointsInSystem(api, hq.system).toList();

//   final myShips = await allMyShips(api).toList();
//   final ship = logger.chooseOne(
//     'Which ship?',
//     choices: myShips,
//     display: (ship) => shipDescription(ship, systemWaypoints),
//   );
//   final maybeRoute =
//       await _routeToNearestUnchartedWaypoint(api, ship.nav.waypointSymbol);
//   if (maybeRoute == null) {
//     logger.info('No route found');
//     return;
//   }
//   logger.info(maybeRoute.toString());
// }
