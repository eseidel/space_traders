import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/arbitrage.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/queries.dart';

Iterable<Price> pricesForWaypoint(PriceData priceData, Waypoint waypoint) {
  return priceData.rawPrices.where((p) => p.waypointSymbol == waypoint.symbol);
}

void logPrices(List<Price> prices) {
  for (final price in prices) {
    logger.info(price.toString());
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final priceData = await PriceData.load(fs);
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);

  final waypoints = await waypointsInSystem(api, hq.system).toList();

  // Given a set of waypoints.
  // Look at the pricing data.
  final localPrices = [
    for (final waypoint in waypoints) ...pricesForWaypoint(priceData, waypoint)
  ];

  final sellOpportunities = <Price>[];
  // Collect the most expensive sell price for each symbol.
  for (final tradeSymbol in TradeSymbol.values) {
    final prices = localPrices.where((p) => p.symbol == tradeSymbol.value);
    if (prices.isEmpty) {
      continue;
    }
    // final medianSellPrice = priceData.medianSellPrice(tradeSymbol.value);
    // if (medianSellPrice == null) {
    //   logger.info('No median price for $tradeSymbol');
    //   continue;
    // }
    final sortedPrices =
        prices.sorted((a, b) => a.sellPrice.compareTo(b.sellPrice));
    // final highestSellPrice = sortedPrices.last;
    // if (highestSellPrice.sellPrice < medianSellPrice) {
    //   continue;
    // }
    // logger.info(
    //   '$tradeSymbol: $medianSellPrice vs ${highestSellPrice.sellPrice}',
    // );
    sellOpportunities.add(sortedPrices.last);
  }

  final purchaseOpportunities = <Price>[];
  // Now do the buy side.
  for (final tradeSymbol in TradeSymbol.values) {
    final prices = localPrices.where((p) => p.symbol == tradeSymbol.value);
    if (prices.isEmpty) {
      continue;
    }
    // final medianBuyPrice = priceData.medianPurchasePrice(tradeSymbol.value);
    // if (medianBuyPrice == null) {
    //   logger.info('No median price for $tradeSymbol');
    //   continue;
    // }
    final sortedPrices =
        prices.sorted((a, b) => a.purchasePrice.compareTo(b.purchasePrice));
    // final lowestBuyPrice = sortedPrices.first;
    // if (lowestBuyPrice.purchasePrice > medianBuyPrice) {
    //   continue;
    // }
    // logger.info(
    //   '$tradeSymbol: $medianBuyPrice vs ${lowestBuyPrice.purchasePrice}',
    // );
    purchaseOpportunities.add(sortedPrices.first);
  }

  // Find a route that connects them.
  final deals = <Deal>[];
  for (final sell in sellOpportunities) {
    for (final buy in purchaseOpportunities) {
      if (sell.symbol != buy.symbol) {
        continue;
      }
      final deal = Deal(
        sourceSymbol: buy.waypointSymbol,
        destinationSymbol: sell.waypointSymbol,
        purchasePrice: buy.purchasePrice,
        sellPrice: sell.sellPrice,
        tradeSymbol: TradeSymbol.fromJson(buy.symbol)!,
      );
      if (deal.profit < 0) {
        continue;
      }
      deals.add(deal);
    }
  }

  final sortedDeals = deals.sorted((a, b) => b.profit.compareTo(a.profit));
  logDeals(sortedDeals);
}
