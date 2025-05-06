import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Returns the symbol of a waypoint in the system missing a chart.
WaypointSymbol? waypointSymbolNeedingCharting(
  SystemsSnapshot systems,
  ChartingSnapshot charts,
  Ship ship,
  SystemSymbol systemSymbol, {
  required bool Function(SystemWaypoint waypointSymbol)? filter,
}) {
  final system = systems.systemBySymbol(systemSymbol);
  final start =
      ship.systemSymbol == system.symbol
          ? ship.waypointSymbol
          // This is only ever called with systems with jumpgates.
          : system.jumpGateWaypoints.first.symbol;
  final startWaypoint = systems.waypoint(start);
  final systemWaypoints = system.waypoints.sortedBy<num>(
    (w) => w.distanceTo(startWaypoint),
  );

  for (final systemWaypoint in systemWaypoints) {
    if (filter != null && !filter(systemWaypoint)) {
      continue;
    }
    final waypointSymbol = systemWaypoint.symbol;
    // We use a ChartingSnapshot here which could be stale. If it is we
    // could end up sending a probe to a waypoint which is already charted.  Our
    // idle_queue is responsible for keeping our charting cache up to date and
    // should make such unlikely.
    // If we have a chart for this waypoint, skip it.
    if (charts.isCharted(waypointSymbol) != true) {
      shipInfo(
        ship,
        '$waypointSymbol (${systemWaypoint.type}) is '
        'missing chart, routing.',
      );
      return waypointSymbol;
    }
  }
  return null;
}

/// Returns the closet waypoint worth exploring.
WaypointSymbol? nextUnchartedWaypointSymbol(
  SystemsSnapshot systems,
  ChartingSnapshot charts,
  SystemConnectivity systemConnectivity,
  Ship ship, {
  required SystemSymbol startSystemSymbol,
  bool Function(SystemWaypoint waypointSymbol)? filter,
  int maxJumps = 5,
}) {
  // Walk through the list finding one missing either a chart or market data.
  for (final (systemSymbol, _) in systemConnectivity.systemSymbolsInJumpRadius(
    systems,
    startSystem: startSystemSymbol,
    maxJumps: maxJumps,
  )) {
    final symbol = waypointSymbolNeedingCharting(
      systems,
      charts,
      ship,
      systemSymbol,
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
  final chart = await caches.waypoints.fetchChart(ship.waypointSymbol);
  // Save neededChart to decide if this stop completes the behavior.
  final neededChart = chart == null;
  if (neededChart) {
    await chartWaypointAndLog(
      api,
      db,
      caches.charting,
      caches.static.waypointTraits,
      ship,
    );
  }
  // We still do market visits even if we've already charted this waypoint.
  await visitLocalMarket(api, db, caches, ship, getNow: getNow);
  await visitLocalShipyard(
    db,
    api,
    caches.waypoints,
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
  final maxJumps = config.charterMaxJumps;
  final behaviors = await BehaviorSnapshot.load(db);
  final ships = await ShipSnapshot.load(db);
  // TODO(eseidel): We shouldn't pull all charting data here.
  // Instead we should keep a cache of fully charted systems or something?
  final charts = await ChartingSnapshot.load(db);
  final systems = await db.snapshotAllSystems();
  final destinationSymbol = centralCommand.nextWaypointToChart(
    ships,
    behaviors,
    systems,
    charts,
    caches.systemConnectivity,
    ship,
    maxJumps: maxJumps,
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
  final systemSymbol = ship.systemSymbol;
  if (!centralCommand.chartAsteroidsInSystem(systemSymbol)) {
    shipErr(
      ship,
      'Charted reachable systems within $maxJumps jumps, '
      'charting asteroids in $systemSymbol.',
    );
    centralCommand.setChartAsteroidsInSystem(systemSymbol);
    return JobResult.wait(null);
  }

  // If we get here, we've explored all systems we can reach.
  throw const JobException('Charted all known systems', Duration(minutes: 20));
}

/// Advance the system watcher.
final advanceCharter = const MultiJob('Charter', [doCharter]).run;
