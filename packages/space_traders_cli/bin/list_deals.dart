import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_cli/arbitrage.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final priceData = await PriceData.load(fs);
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system).toList();
  final marketplaceWaypoints =
      systemWaypoints.where((w) => w.hasMarketplace).toList();

  final currentWaypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );
  final allMarkets = await getAllMarkets(api, systemWaypoints).toList();
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