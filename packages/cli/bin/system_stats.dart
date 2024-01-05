import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  logger.info('Starting from $startSystemSymbol, known reachable:');
  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);

  final reachableSystems =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();
  logger.info('${reachableSystems.length} systems');

  var jumpGates = 0;
  var asteroids = 0;
  var waypointCount = 0;
  for (final systemSymbol in reachableSystems) {
    final systemRecord = systemsCache[systemSymbol];
    waypointCount += systemRecord.waypoints.length;
    jumpGates += systemRecord.jumpGateWaypoints.length;
    asteroids += systemRecord.waypoints.where((w) => w.isAsteroid).length;
  }
  logger.info('$waypointCount waypoints');

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

  String p(double d) => '${(d * 100).round()}%';

  logger
    ..info(' $chartedWaypoints charted non-asteroid '
        '(${p(nonAsteroidChartPercent)})')
    ..info(' $chartedAsteroids charted asteroid '
        '(${p(asteroidChartPercent)})');

  // How many markets?
  final marketListingCache = MarketListingCache.load(fs);
  var markets = 0;
  for (final listing in marketListingCache.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      markets += 1;
    }
  }
  logger.info('$markets markets');

  // How many shipyards?
  final shipyardListingCache = ShipyardListingCache.load(fs);
  var shipyards = 0;
  for (final listing in shipyardListingCache.listings) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = listing.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      shipyards += 1;
    }
  }
  logger
    ..info('$shipyards shipyards')
    ..info('$jumpGates jump gates');

  // How many are cached?
  var cachedJumpGates = 0;
  for (final record in jumpGateCache.values) {
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

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
