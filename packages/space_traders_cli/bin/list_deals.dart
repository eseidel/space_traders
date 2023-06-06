import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);
  final marketCache = MarketCache(waypointCache);

  final priceData = await PriceData.load(fs);
  final hq = await waypointCache.getAgentHeadquarters();
  final marketplaceWaypoints =
      await waypointCache.marketWaypointsForSystem(hq.systemSymbol);
  final currentWaypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );
  final allMarkets =
      await marketCache.marketsInSystem(hq.systemSymbol).toList();
  // Fetch all marketplace data
  final localMarket =
      allMarkets.firstWhere((m) => m.symbol == currentWaypoint.symbol);
  final otherMarkets =
      allMarkets.where((m) => m.symbol != localMarket.symbol).toList();

  final deals = enumeratePossibleDeals(priceData, localMarket, otherMarkets);
  final sortedDeals = deals.sorted((a, b) => a.profit.compareTo(b.profit));
  if (sortedDeals.isEmpty) {
    logger.info('No deals found.  Probably no ship at this waypoint.');
    return;
  }
  logDeals(sortedDeals);
}
