import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:collection/collection.dart';

WaypointSymbol _centralWaypointInSystem(
  SystemsCache systems,
  SystemSymbol system,
) {
  final zero = WaypointPosition(0, 0, system);
  final waypoints = systems[system]
      .waypoints
      .sortedBy<num>((w) => w.position.distanceTo(zero));
  return waypoints.first.symbol;
}

RoutePlan? _shortestPathTo(
  SystemConnectivity systemConnectivity,
  RoutePlanner routePlanner,
  SystemsCache systemsCache,
  SystemSymbol systemSymbol,
  Ship ship,
) {
  final startClusterId =
      systemConnectivity.clusterIdForSystem(ship.systemSymbol);
  final maxFuel = ship.frame.fuelCapacity;
  final system = systemsCache[systemSymbol];
  final nearbySystems = systemsCache.systems.where(
    (s) =>
        s.symbol != systemSymbol &&
        systemConnectivity.clusterIdForSystem(s.symbol) == startClusterId &&
        s.distanceTo(system) < maxFuel,
  );
  final routes = <RoutePlan>[];
  for (final nearbySystem in nearbySystems) {
    // Figure out the time to route from current location to the jumpgate
    // for nearbySystem.
    final jumpGate = nearbySystem.jumpGateWaypoints.first;
    final route = routePlanner.planRoute(
      ship.shipSpec,
      start: ship.waypointSymbol,
      end: jumpGate.symbol,
    );
    if (route != null) {
      routes.add(route);
    }
  }
  if (routes.isEmpty) {
    return null;
  }
  final plan = routes.sortedBy((r) => r.duration).first;
  final actions = List<RouteAction>.from(plan.actions);
  final centralSymbol = _centralWaypointInSystem(systemsCache, systemSymbol);
  final nearbySystem = systemsCache[actions.last.endSymbol.system];
  final distance = nearbySystem.distanceTo(system);
  final seconds = warpTimeByDistanceAndSpeed(
    distance: distance,
    shipSpeed: ship.shipSpec.speed,
    flightMode: ShipNavFlightMode.CRUISE,
  );
  final fuel = fuelUsedByDistance(
    distance,
    ShipNavFlightMode.CRUISE,
  );
  actions.add(
    RouteAction(
      startSymbol: plan.endSymbol,
      endSymbol: centralSymbol,
      type: RouteActionType.warpCruise,
      seconds: seconds,
      fuelUsed: fuel,
    ),
  );
  return plan.copyWith(actions: actions);
}

/// Find the closest system to the seed system that is not in the same cluster.
Future<RoutePlan?> _routeToClosestSystemToSeed(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  RoutePlanner routePlanner,
  Ship ship, {
  required SystemSymbol mainClusterSystemSymbol,
  bool Function(SystemSymbol waypointSymbol)? filter,
}) async {
  final mainClusterId =
      systemConnectivity.clusterIdForSystem(mainClusterSystemSymbol);
  final starterSystems = findInterestingSystems(systemsCache);
  final unreachableSystems = starterSystems
      .where(
        (systemSymbol) =>
            systemConnectivity.clusterIdForSystem(systemSymbol) !=
            mainClusterId,
      )
      .toList();

  final plans = <RoutePlan>[];
  for (final systemSymbol in unreachableSystems) {
    if (filter != null && !filter(systemSymbol)) {
      continue;
    }
    final plan = _shortestPathTo(
      systemConnectivity,
      routePlanner,
      systemsCache,
      systemSymbol,
      ship,
    );
    if (plan != null) {
      plans.add(plan);
    }
  }
  plans.sortBy((p) => p.duration);
  return plans.firstOrNull;
}

/// Returns the next system symbol to seed.
Future<RoutePlan?> routeToNextSystemToSeed(
  AgentCache agentCache,
  ShipSnapshot ships,
  BehaviorSnapshot behaviors,
  SystemsCache systems,
  RoutePlanner routePlanner,
  SystemConnectivity connectivity,
  Ship ship,
) async {
  // Get all interesting systems which do not have ships in them or ships
  // headed towards them.
  final occupiedClusters = <int>{};
  for (final ship in ships.ships) {
    final id = connectivity.clusterIdForSystem(ship.systemSymbol);
    if (id != null) {
      occupiedClusters.add(id);
    }
  }
  for (final state in behaviors.states) {
    final route = state.routePlan;
    if (route != null) {
      final id = connectivity.clusterIdForSystem(route.endSymbol.system);
      if (id != null) {
        occupiedClusters.add(id);
      }
    }
  }

  final route = await _routeToClosestSystemToSeed(
    systems,
    connectivity,
    routePlanner,
    ship,
    mainClusterSystemSymbol: agentCache.headquartersSystemSymbol,
    filter: (SystemSymbol systemSymbol) {
      final clusterId = connectivity.clusterIdForSystem(systemSymbol);
      // Don't visit systems we already have a ship in.
      return !occupiedClusters.contains(clusterId);
    },
  );
  return route;
}

/// One loop of the charting logic.
Future<JobResult> doSeeder(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // If we're already off the main jump gate network, nothing to do.
  final hqSystem = caches.agent.headquartersSystemSymbol;
  final mainClusterId = caches.systemConnectivity.clusterIdForSystem(hqSystem);
  if (mainClusterId !=
      caches.systemConnectivity.clusterIdForSystem(ship.systemSymbol)) {
    throw JobException(
      'Nothing to do, ${ship.shipSymbol} is already off network.',
      const Duration(hours: 1),
    );
  }
  // Otherwise our job is to get off the main jump gate network.
  // Figure out what the best system to go to is.
  // Make sure nothing else is already headed there.
  // And route there.
  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);
  final route = assertNotNull(
    await routeToNextSystemToSeed(
      caches.agent,
      ships,
      behaviors,
      caches.systems,
      caches.routePlanner,
      caches.systemConnectivity,
      ship,
    ),
    'No system to seed.',
    const Duration(hours: 1),
  );
  // This job is done as soon as this route is complete.
  // Then the explorer should try to start trading?
  await beingRouteAndLog(api, db, centralCommand, caches, ship, state, route);

  return JobResult.complete();
}

/// Advance the seeder behavior.
final advanceSeeder = const MultiJob('Seeder', [
  doSeeder,
]).run;
