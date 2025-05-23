import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/warp_pathing.dart';

void main(List<String> args) async {
  await runOffline(args, command);
}

// RoutePlan? shortestPathTo(
//   SystemConnectivity systemConnectivity,
//   RoutePlanner routePlanner,
//
//   SystemSymbol systemSymbol,
//   Ship ship,
// ) {
//   final maxFuel = ship.frame.fuelCapacity;
//   final system = systemsCache[systemSymbol];
//   final nearbySystems = systemsCache.systems.where(
//     (s) =>
//         s.symbol != systemSymbol &&
//         systemConnectivity.existsJumpPathBetween(s.symbol,
//  ship.systemSymbol) &&
//         s.distanceTo(system) < maxFuel,
//   );
//   final routes = <RoutePlan>[];
//   for (final nearbySystem in nearbySystems) {
//     // Figure out the time to route from current location to the jumpgate
//     // for nearbySystem.
//     final jumpGate = nearbySystem.jumpGateWaypoints.first;
//     final route = routePlanner.planRoute(
//       ship.shipSpec,
//       start: ship.waypointSymbol,
//       end: jumpGate.symbol,
//     );
//     if (route != null) {
//       routes.add(route);
//     }
//   }
//   if (routes.isEmpty) {
//     return null;
//   }
//   final plan = routes.sortedBy((r) => r.duration).first;
//   final actions = List<RouteAction>.from(plan.actions);
//   // Should pick something more central.
//   final end = system.jumpGateWaypoints.first;
//   final nearbySystem = systemsCache[actions.last.endSymbol.system];
//   final distance = nearbySystem.distanceTo(system);
//   final seconds = warpTimeByDistanceAndSpeed(
//     distance: distance,
//     shipSpeed: ship.shipSpec.speed,
//     flightMode: ShipNavFlightMode.CRUISE,
//   );
//   final fuel = fuelUsedByDistance(
//     distance,
//     ShipNavFlightMode.CRUISE,
//   );
//   actions.add(
//     RouteAction(
//       startSymbol: plan.endSymbol,
//       endSymbol: end.symbol,
//       type: RouteActionType.warpCruise,
//       seconds: seconds,
//       fuelUsed: fuel,
//     ),
//   );
//   return plan.copyWith(actions: actions);
// }

Future<void> command(Database db, ArgResults argResults) async {
  // Systems to visit:
  final marketListings = await db.marketListings.snapshotAll();
  final systemsToWatch = marketListings.systemsWithAtLeastNMarkets(5);

  final systemsCache = await db.systems.snapshotAllSystems();
  final ships = await ShipSnapshot.load(db);

  // Find ones not in our main cluster.
  final systemConnectivity = await loadSystemConnectivity(db);
  final agent = await db.getMyAgent();
  final hqSystem = agent!.headquarters.system;

  final explorer = ships.ships.firstWhere((s) => s.isExplorer);

  final unreachableSystems = systemsToWatch
      .where(
        (systemSymbol) =>
            !systemConnectivity.existsJumpPathBetween(systemSymbol, hqSystem),
      )
      .toList();

  // Look check all systems within 800 units of an unreachable system for
  // a reachable system.
  final shipSpec = explorer.shipSpec;
  final maxFuel = shipSpec.fuelCapacity;
  logger
    ..info('Systems disconnected from $hqSystem within $maxFuel fuel via warp')
    ..info('with travel time by explorer at ${explorer.waypointSymbol}');

  for (final systemSymbol in unreachableSystems) {
    final system = systemsCache.systemBySymbol(systemSymbol);
    final actions = findRouteBetweenSystems(
      systemsCache,
      systemConnectivity,
      explorer.shipSpec,
      start: explorer.waypointSymbol,
      // Pick the waypoint closest to our current location?
      end: system.waypoints.first.symbol,
      sellsFuel: await defaultSellsFuel(db),
    );
    if (actions != null) {
      final plan = RoutePlan(
        fuelCapacity: shipSpec.fuelCapacity,
        shipSpeed: shipSpec.speed,
        actions: actions,
      );
      logger.info('  $systemSymbol: ${describeRoutePlan(plan)}');
    }
  }
}
