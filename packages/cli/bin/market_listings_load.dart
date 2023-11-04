import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => 0);
  final systems = await SystemsCache.load(fs);
  final staticCaches = StaticCaches.load(fs);
  final charting = ChartingCache.load(fs, staticCaches.waypointTraits);
  final construction = ConstructionCache.load(fs);
  final waypointCache = WaypointCache(api, systems, charting, construction);
  final agentCache = AgentCache.loadCached(fs)!;
  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);

  final systemSymbol = agentCache.agent.headquartersSymbol.systemSymbol;
  final waypoints = await waypointCache.waypointsInSystem(systemSymbol);
  final marketWaypoints =
      waypoints.where((waypoint) => waypoint.hasMarketplace);
  logger.info('Found ${marketWaypoints.length} market waypoints');
  for (final waypoint in marketWaypoints) {
    if (marketListings.marketListingForSymbol(waypoint.waypointSymbol) !=
        null) {
      continue;
    }
    final market = await getMarket(api, waypoint);
    logger.info('Adding market for ${waypoint.waypointSymbol}');
    marketListings.addMarket(market);
  }

  // required or main() will hang
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
