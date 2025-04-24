import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

class SystemStats {
  SystemStats({
    required this.startSystem,
    required this.totalSystems,
    required this.totalWaypoints,
    required this.totalJumpgates,
    required this.reachableSystems,
    required this.reachableWaypoints,
    required this.reachableMarkets,
    required this.reachableShipyards,
    required this.reachableAsteroids,
    required this.reachableJumpGates,
    required this.chartedWaypoints,
    required this.chartedAsteroids,
    required this.chartedJumpGates,
    required this.cachedJumpGates,
  });

  final SystemSymbol startSystem;

  // Total values we can get from the systems cache.
  final int totalSystems;
  final int totalWaypoints;
  final int totalJumpgates;

  /// Counts we have from our own data.
  final int reachableSystems;
  final int reachableWaypoints;
  final int reachableMarkets;
  final int reachableShipyards;
  final int reachableAsteroids;
  final int reachableJumpGates;

  /// Charted counts.
  final int chartedWaypoints;
  final int chartedAsteroids;
  final int chartedJumpGates;

  /// Cached counts (similar to charted)
  final int cachedJumpGates;

  double get asteroidChartPercent => chartedAsteroids / reachableAsteroids;
  double get nonAsteroidChartPercent =>
      (chartedWaypoints - chartedAsteroids) /
      (reachableWaypoints - reachableAsteroids);

  double get reachableSystemPercent => reachableSystems / totalSystems;
  double get reachableWaypointPercent => reachableWaypoints / totalWaypoints;
  double get reachableJumpGatePercent => reachableJumpGates / totalJumpgates;
}

Future<SystemStats> computeSystemStats({
  required FileSystem fs,
  required Database db,
  required SystemSymbol startSystemSymbol,
}) async {
  final systemsCache = SystemsCache.load(fs);
  // Can't use loadSystemConnectivity because need jumpGateSnapshot later.
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity = SystemConnectivity.fromJumpGates(
    jumpGateSnapshot,
    constructionSnapshot,
  );

  var totalSystems = 0;
  var totalJumpgates = 0;
  var totalWaypoints = 0;
  for (final system in systemsCache.systems) {
    totalSystems += 1;
    totalWaypoints += system.waypoints.length;
    totalJumpgates += system.jumpGateWaypoints.length;
  }

  final reachableSystems =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();

  var jumpGates = 0;
  var asteroids = 0;
  var waypointCount = 0;
  for (final systemSymbol in reachableSystems) {
    final systemRecord = systemsCache[systemSymbol];
    waypointCount += systemRecord.waypoints.length;
    jumpGates += systemRecord.jumpGateWaypoints.length;
    asteroids += systemRecord.waypoints.where((w) => w.isAsteroid).length;
  }

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

  // How many are cached?
  var cachedJumpGates = 0;
  for (final record in jumpGateSnapshot.values) {
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      cachedJumpGates += 1;
    }
  }

  // How many blocked connections?
  // To how many unique blocked endpoints?

  return SystemStats(
    startSystem: startSystemSymbol,
    totalJumpgates: totalJumpgates,
    totalSystems: totalSystems,
    totalWaypoints: totalWaypoints,
    reachableWaypoints: waypointCount,
    reachableMarkets: markets,
    reachableShipyards: shipyards,
    reachableAsteroids: asteroids,
    reachableJumpGates: jumpGates,
    cachedJumpGates: cachedJumpGates,
    chartedWaypoints: chartedWaypoints,
    chartedAsteroids: chartedAsteroids,
    chartedJumpGates: chartedJumpGates,
    reachableSystems: reachableSystems.length,
  );
}

String statsToString(SystemStats stats) {
  // Save ourselves some typing.
  final s = stats;
  String p(double d) => '${(d * 100).round()}%';

  return '''
Starting from ${s.startSystem}, known reachable:
${s.reachableSystems} systems (${p(s.reachableSystemPercent)} of ${s.totalSystems})
${s.reachableWaypoints} waypoints (${p(s.reachableWaypointPercent)} of ${s.totalWaypoints})
 ${s.chartedWaypoints} charted non-asteroid (${p(s.nonAsteroidChartPercent)})
 ${s.chartedAsteroids} charted asteroid (${p(s.asteroidChartPercent)})
${s.reachableMarkets} markets
${s.reachableShipyards} shipyards
${s.reachableJumpGates} jump gates (${p(s.reachableJumpGatePercent)} of ${s.totalJumpgates})
 ${s.cachedJumpGates} cached
 ${s.chartedJumpGates} charted
''';
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol = await startSystemFromArg(
    db,
    argResults.rest.firstOrNull,
  );

  final stats = await computeSystemStats(
    fs: fs,
    db: db,
    startSystemSymbol: startSystemSymbol,
  );
  logger.info(statsToString(stats));
}

void main(List<String> args) async {
  await runOffline(args, command);
}
