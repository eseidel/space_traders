import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';

WaypointSymbol _centralWaypoint(List<SystemWaypoint> waypoints) {
  final zero = WaypointPosition(0, 0, waypoints.first.system);
  final sorted = waypoints.sortedBy<num>((w) => w.position.distanceTo(zero));
  return sorted.first.symbol;
}

RoutePlan? _shortestPathTo(
  SystemConnectivity systemConnectivity,
  RoutePlanner routePlanner,
  SystemsSnapshot systems,
  SystemSymbol systemSymbol,
  Ship ship,
) {
  final maxFuel = ship.frame.fuelCapacity;
  final system = systems.systemRecordBySymbol(systemSymbol);
  final nearbySystems = systems.records.where(
    (s) =>
        s.symbol != systemSymbol &&
        systemConnectivity.existsJumpPathBetween(s.symbol, ship.systemSymbol) &&
        s.distanceTo(system) < maxFuel,
  );
  final routes = <RoutePlan>[];
  for (final nearbySystem in nearbySystems) {
    // Figure out the time to route from current location to the jumpgate
    // for nearbySystem.
    final jumpGate = systems.jumpGateWaypointForSystem(nearbySystem.symbol);
    final route = routePlanner.planRoute(
      ship.shipSpec,
      start: ship.waypointSymbol,
      end: jumpGate!.symbol,
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
  final centralSymbol = _centralWaypoint(
    systems.waypointsInSystem(systemSymbol),
  );
  final nearbySystem = systems.systemRecordBySymbol(
    actions.last.endSymbol.system,
  );
  final distance = nearbySystem.distanceTo(system);
  final seconds = warpTimeByDistanceAndSpeed(
    distance: distance,
    shipSpeed: ship.shipSpec.speed,
    flightMode: ShipNavFlightMode.CRUISE,
  );
  final fuel = fuelUsedByDistance(distance, ShipNavFlightMode.CRUISE);
  if (actions.first.type == RouteActionType.emptyRoute) {
    actions.removeAt(0);
  }
  // TODO(eseidel): Do jump gate markets have fuel?
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
  SystemsSnapshot systemsCache,
  SystemConnectivity systemConnectivity,
  RoutePlanner routePlanner,
  Ship ship, {
  required SystemSymbol mainClusterSystemSymbol,
  bool Function(SystemSymbol waypointSymbol)? filter,
}) async {
  final starterSystems = findInterestingSystems(systemsCache);
  final unreachableSystems =
      starterSystems
          .where(
            (systemSymbol) => systemConnectivity.existsJumpPathBetween(
              systemSymbol,
              mainClusterSystemSymbol,
            ),
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
  SystemsSnapshot systems,
  RoutePlanner routePlanner,
  SystemConnectivity connectivity,
  Ship ship,
) async {
  // Get all interesting systems which do not have ships in them or ships
  // headed towards them.
  final systemSymbols = <SystemSymbol>{};
  for (final ship in ships.ships) {
    systemSymbols.add(ship.systemSymbol);
  }
  for (final state in behaviors.states) {
    final route = state.routePlan;
    if (route != null) {
      systemSymbols.add(route.endSymbol.system);
    }
  }
  final occupiedClusters =
      systemSymbols
          .map((s) => connectivity.clusterIdForSystem(s))
          .nonNulls
          .toSet();

  final route = await _routeToClosestSystemToSeed(
    systems,
    connectivity,
    routePlanner,
    ship,
    mainClusterSystemSymbol: agentCache.headquartersSystemSymbol,
    filter: (SystemSymbol systemSymbol) {
      final clusterId = connectivity.clusterIdForSystem(systemSymbol);
      // If this system doesn't have a cluster id, check our system list.
      if (clusterId == null) {
        return !systemSymbols.contains(systemSymbol);
      }
      // Otherwise check our cluster id list.
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
  if (caches.systemConnectivity.existsJumpPathBetween(
    ship.systemSymbol,
    hqSystem,
  )) {
    shipErr(ship, 'Successfully off network in ${ship.systemSymbol}!');
    // Get the shipyard for this system.
    // replace our state with a buy-ship job there.

    // If we have already bought a probe in this system, get back onto
    // the main jumpgate network and look for the next system to seed?

    throw JobException(
      'Nothing to do, ${ship.symbol} is already off network.',
      const Duration(hours: 1),
    );
  }
  // Otherwise our job is to get off the main jump gate network.
  // Figure out what the best system to go to is.
  // Make sure nothing else is already headed there.
  // And route there.
  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);
  final systems = await db.systems.snapshot();
  final route = assertNotNull(
    await routeToNextSystemToSeed(
      caches.agent,
      ships,
      behaviors,
      systems,
      caches.routePlanner,
      caches.systemConnectivity,
      ship,
    ),
    'No system to seed.',
    const Duration(hours: 1),
  );

  shipErr(ship, 'Seeder starting route to ${route.endSymbol.system}.');
  shipInfo(ship, describeRoutePlan(route));

  final maybeMarket = await visitLocalMarket(api, db, caches, ship);
  if (maybeMarket != null) {
    await refuelIfNeededAndLog(
      api,
      db,
      caches.agent,
      maybeMarket,
      ship,
      medianFuelPurchasePrice: 72,
    );
  }

  // This job is done as soon as this route is complete.
  // Then the explorer should try to start trading?
  final waitUntil = await beingRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    route,
  );
  // If we return complete here the caller would delete the behavior state.
  return JobResult.wait(waitUntil);
}

/// Advance the seeder behavior.
final advanceSeeder = const MultiJob('Seeder', [doSeeder]).run;
