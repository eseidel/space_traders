import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  logger.info('Starting from $startSystemSymbol, known reachable:');
  final systemsCache = SystemsCache.load(fs);
  // Can't use loadSystemConnectivity because need jumpGateSnapshot later.
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateSnapshot, constructionSnapshot);

  var totalSystems = 0;
  var totalJumpgates = 0;
  var totalWaypoints = 0;
  for (final system in systemsCache.systems) {
    totalSystems += 1;
    totalWaypoints += system.waypoints.length;
    totalJumpgates += system.jumpGateWaypoints.length;
  }

  String p(double d) => '${(d * 100).round()}%';

  final reachableSystems =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();
  final reachableSystemPercent = reachableSystems.length / totalSystems;
  logger.info('${reachableSystems.length} systems '
      '(${p(reachableSystemPercent)} of $totalSystems)');

  var jumpGates = 0;
  var asteroids = 0;
  var waypointCount = 0;
  for (final systemSymbol in reachableSystems) {
    final systemRecord = systemsCache[systemSymbol];
    waypointCount += systemRecord.waypoints.length;
    jumpGates += systemRecord.jumpGateWaypoints.length;
    asteroids += systemRecord.waypoints.where((w) => w.isAsteroid).length;
  }
  final reachableWaypointPercent = waypointCount / totalWaypoints;
  logger.info('$waypointCount waypoints '
      '(${p(reachableWaypointPercent)} of $totalWaypoints)');

  // How many waypoints are charted?
  final chartingSnapshot = await ChartingSnapshot.load(db);
  var chartedWaypoints = 0;
  var chartedAsteroids = 0;
  var chartedJumpGates = 0;
  for (final record in chartingSnapshot.records) {
    if (!record.isCharted) {
      continue;
    }
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (!reachableSystems.contains(systemSymbol)) {
      continue;
    }
    chartedWaypoints += 1;
    final waypoint = systemsCache.waypoint(record.waypointSymbol);
    if (waypoint.isJumpGate) {
      chartedJumpGates += 1;
    }
    if (waypoint.isAsteroid) {
      chartedAsteroids += 1;
    }
  }
  final nonAsteroidCount = waypointCount - asteroids;
  final nonAsteroidCartedCount = chartedWaypoints - chartedAsteroids;
  final nonAsteroidChartPercent = nonAsteroidCartedCount / nonAsteroidCount;
  final asteroidChartPercent = chartedAsteroids / asteroids;

  logger
    ..info(' $chartedWaypoints charted non-asteroid '
        '(${p(nonAsteroidChartPercent)})')
    ..info(' $chartedAsteroids charted asteroid '
        '(${p(asteroidChartPercent)})');

  // How many markets?
  final marketListings = await MarketListingSnapshot.load(db);
  var markets = 0;
  for (final listing in marketListings.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      markets += 1;
    }
  }
  logger.info('$markets markets');

  // How many shipyards?
  final shipyardListings = await ShipyardListingSnapshot.load(db);
  var shipyards = 0;
  for (final listing in shipyardListings.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      shipyards += 1;
    }
  }
  final reachableJumpGatePercent = jumpGates / totalJumpgates;
  logger
    ..info('$shipyards shipyards')
    ..info('$jumpGates jump gates'
        ' (${p(reachableJumpGatePercent)} of $totalJumpgates)');

  // How many are cached?
  var cachedJumpGates = 0;
  for (final record in jumpGateSnapshot.values) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      cachedJumpGates += 1;
    }
  }
  logger
    ..info(' $cachedJumpGates cached')
    ..info(' $chartedJumpGates charted');

  // How many blocked connections?
  // To how many unique blocked endpoints?
}

void main(List<String> args) async {
  await runOffline(args, command);
}
