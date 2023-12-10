import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Returns the symbol of a waypoint in the system missing a chart.
Future<WaypointSymbol?> waypointSymbolNeedingCharting(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  Ship ship,
  System system, {
  required bool Function(WaypointSymbol waypointSymbol)? filter,
}) async {
  final start = ship.systemSymbol == system.systemSymbol
      ? ship.waypointSymbol
      // This is only ever called with systems with waypoints.
      : system.jumpGateWaypoints.first.waypointSymbol;
  final startWaypoint = systemsCache.waypoint(start);
  final systemWaypoints =
      system.waypoints.sortedBy<num>((w) => w.distanceTo(startWaypoint));

  for (final systemWaypoint in systemWaypoints) {
    final waypointSymbol = systemWaypoint.waypointSymbol;
    if (filter != null && !filter(waypointSymbol)) {
      continue;
    }
    // Try and fetch the waypoint from the server or our cache.
    final isCharted = await waypointCache.isCharted(waypointSymbol);
    if (isCharted) {
      shipInfo(ship, '$waypointSymbol is missing chart, routing.');
      return waypointSymbol;
    }
  }
  return null;
}

/// Returns the closet waypoint worth exploring.
Future<WaypointSymbol?> findNewWaypointSymbolToExplore(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  SystemConnectivity systemConnectivity,
  Ship ship, {
  required SystemSymbol startSystemSymbol,
  bool Function(WaypointSymbol waypointSymbol)? filter,
}) async {
  // Find all systems we know how to reach.
  final reachableSystemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol);
  final reachableSystems =
      reachableSystemSymbols.map(systemsCache.systemBySymbol).toList();

  // Sort systems by distance from the start system.
  final startSystem = systemsCache[startSystemSymbol];
  final sortedSystems = reachableSystems
      .sortedBy<num>((system) => system.distanceTo(startSystem))
      .toList();
  // Walk through the list finding one missing either a chart or market data.
  for (final system in sortedSystems) {
    final symbol = await waypointSymbolNeedingCharting(
      systemsCache,
      waypointCache,
      ship,
      system,
      filter: filter,
    );
    if (symbol != null) {
      return symbol;
    }
  }
  return null;
}

/// One loop of the charting logic.
Future<DateTime?> advanceCharter(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final maxAge = centralCommand.maxAgeForExplorerData;
  final waypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  // Save neededChart to decide if this stop completes the behavior.
  final neededChart = waypoint.chart == null;
  if (neededChart) {
    await chartWaypointAndLog(api, caches.charting, ship);
  }
  // We still do market visits even if we've already charted this waypoint.
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

  if (neededChart) {
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    state.isComplete = true;
    return null;
  }

  final charterSystems =
      centralCommand.otherCharterSystems(ship.shipSymbol).toSet();

  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  final startTime = getNow();
  final destinationSymbol = await findNewWaypointSymbolToExplore(
    caches.systems,
    caches.waypoints,
    caches.systemConnectivity,
    ship,
    startSystemSymbol: ship.systemSymbol,
    // TODO(eseidel): Once we leave the initial system, explorers should stay
    // at least a system apart.
    filter: (waypointSymbol) => !charterSystems.contains(waypointSymbol),
  );
  final endTime = getNow();
  final elapsed = endTime.difference(startTime);
  if (elapsed > const Duration(seconds: 5)) {
    shipErr(
      ship,
      'Took ${approximateDuration(elapsed)} to find next system to explore.',
    );
  }
  if (destinationSymbol != null) {
    return beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      destinationSymbol,
    );
  }
  // If we get here, we've explored all systems within maxJumpDistance jumps
  // of this system.
  shipWarn(ship, 'No unexplored systems near ${waypoint.systemSymbol}.');
  final newMaxAge = centralCommand.shortenMaxAgeForExplorerData();
  shipWarn(
    ship,
    'Shortened maxAge to ${approximateDuration(newMaxAge)} and resuming.',
  );
  return null;
}
