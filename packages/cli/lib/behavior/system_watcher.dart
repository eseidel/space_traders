import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Logic for assigning systems to system watchers.
Map<ShipSymbol, SystemSymbol> assignProbesToSystems(
  SystemConnectivity systemConnectivity,
  MarketListingSnapshot marketListings,
  ShipSnapshot ships,
) {
  // Find systems with at least 5 markets.
  final systemsWithEnoughMarkets = marketListings.systemsWithAtLeastNMarkets(5);

  final assignedProbes = <ShipSymbol, SystemSymbol>{};
  final availableProbes = ships.ships.where((s) => s.isProbe).toList();
  final systemsNeedingProbes = systemsWithEnoughMarkets.toList();
  // First try to assign probes to the systems they are already in.
  for (final probe in availableProbes) {
    final systemSymbol = probe.systemSymbol;
    if (!systemsNeedingProbes.contains(systemSymbol)) {
      continue;
    }
    if (systemsWithEnoughMarkets.contains(systemSymbol)) {
      assignedProbes[probe.symbol] = systemSymbol;
      systemsNeedingProbes.remove(systemSymbol);
    }
  }
  for (final probeSymbol in assignedProbes.keys) {
    availableProbes.removeWhere((s) => s.symbol == probeSymbol);
  }

  // clusterId == null means the system has no jump gate connections, so we
  // use the systemSymbol itself as the id.  Otherwise we use the clusterId.
  // TODO(eseidel): Make clusterId work this way.
  String idForCluster(SystemSymbol systemSymbol) {
    final clusterId = systemConnectivity.clusterIdForSystem(systemSymbol);
    if (clusterId != null) {
      return clusterId.toString();
    }
    return systemSymbol.system;
  }

  final systemsNeededByClusterId = systemsNeedingProbes.groupListsBy(
    idForCluster,
  );

  // Otherwise just assign the remaining probes.
  // TODO(eseidel): We could assign by proximity.
  for (final probe in availableProbes) {
    final clusterId = idForCluster(probe.systemSymbol);
    final systemsNeeded = systemsNeededByClusterId[clusterId];
    if (systemsNeeded == null || systemsNeeded.isEmpty) {
      continue;
    }
    final systemSymbol = systemsNeeded.removeLast();
    assignedProbes[probe.symbol] = systemSymbol;
  }
  final remainingSystems = systemsNeededByClusterId.values.expand((e) => e);
  if (remainingSystems.isNotEmpty) {
    final names = remainingSystems.map((s) => s.systemName).join(', ');
    logger.warn(
      'Failed to assign probes to ${remainingSystems.length} systems: $names',
    );
  }
  return assignedProbes;
}

/// Returns true if the given waypoint is missing either a chart or recent
/// market data.
Future<bool> _isMissingChartOrRecentPriceData(
  Database db,
  Waypoint waypoint, {
  required Duration maxAge,
}) async {
  return waypoint.chart == null ||
      await _isMissingRecentMarketData(db, waypoint, maxAge: maxAge) ||
      await _isMissingRecentShipyardData(db, waypoint, maxAge: maxAge);
}

Future<bool> _isMissingRecentMarketData(
  Database db,
  Waypoint waypoint, {
  required Duration maxAge,
}) async {
  if (!waypoint.hasMarketplace) {
    return false;
  }
  final result = await db.hasRecentMarketPrices(waypoint.symbol, maxAge);
  return !result;
}

Future<bool> _isMissingRecentShipyardData(
  Database db,
  Waypoint waypoint, {
  required Duration maxAge,
}) async {
  if (!waypoint.hasShipyard) {
    return false;
  }
  final result = await db.hasRecentShipyardPrices(waypoint.symbol, maxAge);
  return !result;
}

/// Returns the symbol of a waypoint in the system missing a chart.
Future<WaypointSymbol?> waypointSymbolNeedingUpdate(
  Database db,
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  Ship ship,
  System system, {
  required Duration maxAge,
  required bool Function(WaypointSymbol waypointSymbol)? filter,
  required WaypointCache waypointCache,
}) async {
  final WaypointSymbol? start;
  if (ship.systemSymbol == system.symbol) {
    start = ship.waypointSymbol;
  } else {
    start = system.jumpGateWaypoints.firstOrNull?.symbol;
  }
  final systemWaypoints = system.waypoints.toList(); // Copy so we can sort.
  if (start != null) {
    final startWaypoint = systemsCache.waypoint(start);
    systemWaypoints.sortBy<num>((a) => a.distanceTo(startWaypoint));
  }

  for (final systemWaypoint in systemWaypoints) {
    final waypointSymbol = systemWaypoint.symbol;
    if (filter != null && !filter(waypointSymbol)) {
      continue;
    }
    // Try and fetch the waypoint from the server or our cache.
    final waypoint = await waypointCache.waypoint(waypointSymbol);
    // We know we've updated the waypoint at this point, so if it's not
    // stored in our charting cache, we know it has no chart.
    final isCharted = await chartingCache.isCharted(waypointSymbol);
    if (isCharted == null) {
      throw StateError('Charting cache failed to update.');
    }
    if (!isCharted) {
      shipInfo(ship, '$waypointSymbol is missing chart, routing.');
      return waypointSymbol;
    }
    if (await _isMissingRecentMarketData(db, waypoint, maxAge: maxAge)) {
      shipInfo(
        ship,
        '$waypointSymbol is missing recent '
        '(${approximateDuration(maxAge)}) market data, '
        'routing.',
      );
      return waypointSymbol;
    }
    if (await _isMissingRecentShipyardData(db, waypoint, maxAge: maxAge)) {
      shipInfo(
        ship,
        '$waypointSymbol is missing recent '
        '(${approximateDuration(maxAge)}) shipyard data, '
        'routing.',
      );
      return waypointSymbol;
    }
  }
  return null;
}

Future<JobResult> _travelToAssignedSystem(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final systemSymbol = assertNotNull(
    state.systemWatcherJob?.systemSymbol,
    'No assigned system for ${ship.symbol}.',
    const Duration(minutes: 10),
  );
  if (ship.systemSymbol != systemSymbol) {
    // Not in our assigned system, route there.
    final jumpGate = assertNotNull(
      caches.systems.jumpGateWaypointForSystem(systemSymbol),
      'No jump gate for $systemSymbol.',
      const Duration(minutes: 1),
    );

    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      jumpGate.symbol,
    );
    return JobResult.wait(waitTime);
  }
  return JobResult.complete();
}

/// Logic for watching prices within a single system in a circuit.
Future<JobResult> doSystemWatcher(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // This assumes we're already in the system we're supposed to be in.
  final systemSymbol = ship.systemSymbol;

  final maxAge = centralCommand.maxPriceAgeForSystem(systemSymbol);
  final waypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  final willCompleteBehavior = await _isMissingChartOrRecentPriceData(
    db,
    waypoint,
    maxAge: maxAge,
  );
  // We still do our charting and market visits even if this isn't going to
  // cause us to complete the behavior (e.g. refueling).
  if (waypoint.chart == null) {
    await chartWaypointAndLog(
      api,
      db,
      caches.charting,
      caches.static.waypointTraits,
      ship,
    );
  }
  await visitLocalMarket(api, db, caches, ship, maxAge: maxAge, getNow: getNow);
  await visitLocalShipyard(
    db,
    api,
    caches.waypoints,
    caches.static,
    caches.agent,
    ship,
  );

  if (willCompleteBehavior) {
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    return JobResult.complete();
  }

  final behaviors = await BehaviorSnapshot.load(db);
  final ships = await ShipSnapshot.load(db);
  final avoidWaypoints = centralCommand.waypointsToAvoidInSystem(
    ships,
    behaviors,
    systemSymbol,
    ship.symbol,
  );

  // Walk our nearby waypoints looking for one that needs refresh.
  final destinationSymbol = await waypointSymbolNeedingUpdate(
    db,
    caches.systems,
    caches.charting,
    ship,
    caches.systems[systemSymbol],
    waypointCache: caches.waypoints,
    maxAge: maxAge,
    filter:
        (WaypointSymbol waypointSymbol) =>
            !avoidWaypoints.contains(waypointSymbol),
  );

  if (destinationSymbol != null) {
    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      destinationSymbol,
    );
    return JobResult.wait(waitTime);
  }
  shipWarn(ship, 'No stale markets near waypoints near ${waypoint.symbol}.');

  jobAssert(
    maxAge > const Duration(minutes: 10),
    'Max age for $systemSymbol is already too short, giving up.',
    const Duration(hours: 1),
  );

  // TODO(eseidel): Instead of halving the age, we should figure out what the
  // oldest current record is and set our max-age to half that?
  // That would save us many loops through this on startup.
  final newMaxAge = centralCommand.shortenMaxPriceAgeForSystem(systemSymbol);
  shipWarn(
    ship,
    'Shortened maxAge for $systemSymbol to '
    '${approximateDuration(newMaxAge)} and resuming.',
  );
  return JobResult.wait(null);
}

/// Advance the system watcher.
final advanceSystemWatcher =
    const MultiJob('SystemWatcher', [
      _travelToAssignedSystem,
      doSystemWatcher,
    ]).run;
