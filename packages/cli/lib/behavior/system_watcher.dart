import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Logic for assigning systems to system watchers.
Map<ShipSymbol, SystemSymbol> assignProbesToSystems(
  MarketListingCache marketListingCache,
  ShipCache shipCache,
) {
  // Find systems with at least 5 markets.
  final systemsWithEnoughMarkets =
      marketListingCache.systemsWithAtLeastNMarkets(5);

  final assignedProbes = <ShipSymbol, SystemSymbol>{};
  final availableProbes = shipCache.ships.where((s) => s.isProbe).toList();
  final systemsNeedingProbes = systemsWithEnoughMarkets.toList();
  // First try to assign probes to the systems they are already in.
  for (final probe in availableProbes) {
    final systemSymbol = probe.systemSymbol;
    if (!systemsNeedingProbes.contains(systemSymbol)) {
      continue;
    }
    if (systemsWithEnoughMarkets.contains(systemSymbol)) {
      assignedProbes[probe.shipSymbol] = systemSymbol;
      systemsNeedingProbes.remove(systemSymbol);
    }
  }
  // Otherwise just assign the remaining probes.
  // TODO(eseidel): We could assign by proximity.
  for (final probe in availableProbes) {
    if (systemsNeedingProbes.isEmpty) {
      break;
    }
    final systemSymbol = systemsNeedingProbes.removeLast();
    assignedProbes[probe.shipSymbol] = systemSymbol;
    systemsNeedingProbes.remove(systemSymbol);
  }
  if (systemsNeedingProbes.isNotEmpty) {
    logger.warn('Failed to assign probes to systems: $systemsNeedingProbes');
  }
  return assignedProbes;
}

/// Returns true if the given waypoint is missing either a chart or recent
/// market data.
bool isMissingChartOrRecentPriceData(
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.chart == null ||
      _isMissingRecentMarketData(marketPrices, waypoint, maxAge: maxAge) ||
      _isMissingRecentShipyardData(shipyardPrices, waypoint, maxAge: maxAge);
}

bool _isMissingRecentMarketData(
  MarketPrices marketPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.hasMarketplace &&
      !marketPrices.hasRecentData(
        waypoint.waypointSymbol,
        maxAge: maxAge,
      );
}

bool _isMissingRecentShipyardData(
  ShipyardPrices shipyardPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.hasShipyard &&
      !shipyardPrices.hasRecentData(
        waypoint.waypointSymbol,
        maxAge: maxAge,
      );
}

/// Returns the symbol of a waypoint in the system missing a chart.
Future<WaypointSymbol?> waypointSymbolNeedingUpdate(
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship,
  System system, {
  required Duration maxAge,
  required bool Function(WaypointSymbol waypointSymbol)? filter,
  required WaypointCache waypointCache,
}) async {
  final WaypointSymbol? start;
  if (ship.systemSymbol == system.systemSymbol) {
    start = ship.waypointSymbol;
  } else {
    start = system.jumpGateWaypoints.firstOrNull?.waypointSymbol;
  }
  final systemWaypoints = system.waypoints.toList(); // Copy so we can sort.
  if (start != null) {
    final startWaypoint = systemsCache.waypoint(start);
    systemWaypoints.sort(
      (a, b) =>
          a.distanceTo(startWaypoint).compareTo(b.distanceTo(startWaypoint)),
    );
  }

  for (final systemWaypoint in systemWaypoints) {
    final waypointSymbol = systemWaypoint.waypointSymbol;
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
    if (waypoint.hasMarketplace &&
        !marketPrices.hasRecentData(waypointSymbol, maxAge: maxAge)) {
      shipInfo(
        ship,
        '$waypointSymbol is missing recent '
        '(${approximateDuration(maxAge)}) market data, '
        'routing.',
      );
      return waypointSymbol;
    }
    if (waypoint.hasShipyard &&
        !shipyardPrices.hasRecentData(waypointSymbol, maxAge: maxAge)) {
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
    'No assigned system for ${ship.shipSymbol}.',
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
      jumpGate.waypointSymbol,
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
  final willCompleteBehavior = isMissingChartOrRecentPriceData(
    caches.marketPrices,
    caches.shipyardPrices,
    waypoint,
    maxAge: maxAge,
  );
  // We still do our charting and market visits even if this isn't going to
  // cause us to complete the behavior (e.g. refueling).
  if (waypoint.chart == null) {
    await chartWaypointAndLog(
      api,
      caches.charting,
      caches.static.waypointTraits,
      ship,
    );
  }
  await visitLocalMarket(api, db, caches, ship, maxAge: maxAge, getNow: getNow);
  await visitLocalShipyard(
    api,
    db,
    caches.waypoints,
    caches.shipyardPrices,
    caches.static,
    caches.agent,
    ship,
  );

  if (willCompleteBehavior) {
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    return JobResult.complete();
  }

  final avoidWaypoints =
      centralCommand.waypointsToAvoidInSystem(systemSymbol, ship.shipSymbol);

  // Walk our nearby waypoints looking for one that needs refresh.
  final destinationSymbol = await waypointSymbolNeedingUpdate(
    caches.systems,
    caches.charting,
    caches.marketPrices,
    caches.shipyardPrices,
    ship,
    caches.systems[systemSymbol],
    waypointCache: caches.waypoints,
    maxAge: maxAge,
    filter: (WaypointSymbol waypointSymbol) =>
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

  final newMaxAge = centralCommand.shortenMaxPriceAgeForSystem(systemSymbol);
  shipWarn(
    ship,
    'Shortened maxAge for $systemSymbol to '
    '${approximateDuration(newMaxAge)} and resuming.',
  );
  return JobResult.wait(null);
}

/// Advance the system watcher.
final advanceSystemWatcher = const MultiJob('SystemWatcher', [
  _travelToAssignedSystem,
  doSystemWatcher,
]).run;
