import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Returns the symbol of a waypoint in the system missing a chart.
Future<WaypointSymbol?> waypointSymbolNeedingCharting(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  Ship ship,
  System system, {
  required bool Function(SystemWaypoint waypointSymbol)? filter,
}) async {
  final start = ship.systemSymbol == system.systemSymbol
      ? ship.waypointSymbol
      // This is only ever called with systems with waypoints.
      : system.jumpGateWaypoints.first.waypointSymbol;
  final startWaypoint = systemsCache.waypoint(start);
  final systemWaypoints =
      system.waypoints.sortedBy<num>((w) => w.distanceTo(startWaypoint));

  for (final systemWaypoint in systemWaypoints) {
    if (filter != null && !filter(systemWaypoint)) {
      continue;
    }
    final waypointSymbol = systemWaypoint.waypointSymbol;
    // Try and fetch the waypoint from the server or our cache.
    final isCharted = await waypointCache.isCharted(waypointSymbol);
    if (!isCharted) {
      shipInfo(ship, '$waypointSymbol is missing chart, routing.');
      return waypointSymbol;
    }
  }
  return null;
}

/// Returns the closet waypoint worth exploring.
Future<WaypointSymbol?> nextUnchartedWaypointSymbol(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  SystemConnectivity systemConnectivity,
  Ship ship, {
  required SystemSymbol startSystemSymbol,
  bool Function(SystemWaypoint waypointSymbol)? filter,
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
Future<JobResult> doCharter(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final waypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  // Save neededChart to decide if this stop completes the behavior.
  final neededChart = waypoint.chart == null;
  if (neededChart) {
    await chartWaypointAndLog(api, caches.charting, ship);
  }
  // We still do market visits even if we've already charted this waypoint.
  await visitLocalMarket(api, db, caches, ship, getNow: getNow);
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
    // Charter behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "charter".
    return JobResult.complete();
  }

  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  final destinationSymbol = await centralCommand.nextWaypointToChart(
    caches.systems,
    caches.waypoints,
    caches.systemConnectivity,
    ship,
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
  // If we get here, we've explored all systems we can reach.
  throw const JobException('Charted all known systems', Duration(hours: 1));
}

/// Advance the system watcher.
final advanceCharter = const MultiJob('Charter', [
  doCharter,
]).run;
