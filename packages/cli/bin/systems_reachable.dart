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

  final sytemsCache = SystemsCache.load(fs)!;
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);

  final reachableSystems =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();
  logger.info('${reachableSystems.length} reachable systems');

  var waypointCount = 0;
  for (final systemSymbol in reachableSystems) {
    final systemRecord = sytemsCache[systemSymbol];
    waypointCount += systemRecord.waypoints.length;
  }
  logger.info('containing $waypointCount waypoints');

  // How many waypoints are charted?
  final chartingSnapshot = await ChartingSnapshot.load(db);
  var chartedWaypoints = 0;
  for (final record in chartingSnapshot.records) {
    if (!record.isCharted) {
      continue;
    }
    // We could sort first by system to save ourselves some lookups.
    final systemSymbol = record.waypointSymbol.system;
    if (reachableSystems.contains(systemSymbol)) {
      chartedWaypoints += 1;
    }
  }
  logger.info('$chartedWaypoints charted waypoints');
  // How many markets?
  final tradeGoodCache = TradeGoodCache.load(fs);
  final marketListingCache = MarketListingCache.load(fs, tradeGoodCache);
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
  logger.info('$shipyards shipyards');
  // How many total jump gates (presumably the exact number of systems?)
  // How many blocked connections?
  // To how many unique blocked endpoints?

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
