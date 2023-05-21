import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';

/// Record of a possible abitrage opportunity.
class Deal {
  /// Create a new deal.
  Deal({
    required this.tradeSymbol,
    required this.destinationSymbol,
    required this.purchasePrice,
    required this.sellPrice,
  });

  /// The trade symbol that we're selling.
  final TradeSymbol tradeSymbol;

  /// The symbol of the market we're selling to.
  final String destinationSymbol;

  /// The price we're buying at.
  final int purchasePrice;

  /// The price we're selling at.
  final int sellPrice;
  // Also should take fuel costs into account.
  // And possibly time?

  /// The profit we'll make on this deal.
  int get profit => sellPrice - purchasePrice;
}

int _percentileForTradeType(ExchangeType tradeType) {
  switch (tradeType) {
    case ExchangeType.exchange:
      return 50;
    case ExchangeType.imports:
      return 25;
    case ExchangeType.exports:
      return 75;
  }
}

/// Estimate the current sell price of [tradeSymbol] at [market].
int? estimateSellPrice(
  PriceData priceData,
  TradeSymbol tradeSymbol,
  Market market,
) {
  // We could also grab the current sell price if the market has
  // tradeGoods available, but that would only happen when we have a probe
  // at the market, but aren't recording prices in our priceData.

  final recentSellPrice = priceData.recentSellPrice(
    marketSymbol: market.symbol,
    tradeSymbol: tradeSymbol.value,
  );
  if (recentSellPrice != null) {
    return recentSellPrice;
  }
  final tradeType = market.exchangeType(tradeSymbol.value)!;
  // Our price data is currently only for market imports/exports, not exchanges.
  // Exports aren't necessarily even possible to sell to.
  // This might not actually be true!
  if (tradeType != ExchangeType.imports) {
    return null;
  }
  // print('Looking up ${tradeSymbol.value} ${market.symbol} $tradeType');
  final percentile = _percentileForTradeType(tradeType);
  return priceData.percentileForSellPrice(tradeSymbol.value, percentile);
}

/// Enumerate all possible deals that could be made between [localMarket] and
/// [otherMarkets].
Iterable<Deal> enumeratePossibleDeals(
  PriceData priceData,
  Market localMarket,
  List<Market> otherMarkets,
) sync* {
  for (final otherMarket in otherMarkets) {
    for (final sellSymbol in otherMarket.allTradeSymbols) {
      final sellPrice = estimateSellPrice(priceData, sellSymbol, otherMarket);
      if (sellPrice == null) {
        continue;
      }
      for (final purchaseGood in localMarket.tradeGoods) {
        if (sellSymbol.value == purchaseGood.symbol) {
          yield Deal(
            tradeSymbol: sellSymbol,
            destinationSymbol: otherMarket.symbol,
            purchasePrice: purchaseGood.purchasePrice,
            sellPrice: sellPrice,
          );
        }
      }
    }
  }
}

/// Log proposed [deals] to the console.
void logDeals(List<Deal> deals) {
  for (final deal in deals) {
    logger.info(
      '${deal.tradeSymbol.value} ${deal.destinationSymbol} '
      '${deal.purchasePrice} ${deal.sellPrice} ${deal.profit}',
    );
  }
}

/// Find the best deal that can be made from [currentWaypoint].
Future<Deal?> findBestDeal(
  Api api,
  PriceData priceData,
  Ship ship,
  Waypoint currentWaypoint,
  List<Market> allMarkets,
) async {
  // Fetch all marketplace data
  final localMarket =
      allMarkets.firstWhere((m) => m.symbol == currentWaypoint.symbol);
  final otherMarkets =
      allMarkets.where((m) => m.symbol != localMarket.symbol).toList();

  final deals = enumeratePossibleDeals(priceData, localMarket, otherMarkets);
  final sortedDeals = deals.sorted((a, b) => a.profit.compareTo(b.profit));
  // logDeals(sortedDeals);
  final bestDeal = sortedDeals.lastOrNull;
  if (bestDeal == null || bestDeal.profit <= 0) {
    return null;
  }
  return bestDeal;

  // The simplest possible thing is get the list of trade symbols sold at this
  // marketplace, and then for each trade symbol, get the price at this
  // marketplace, and then for each trade symbol, get the prices at all other
  // marketplaces, and then sort by assumed profit.
  // If we don't have a destination price, assume 50th percentile.

  // Construct all possible deals.
  // Get the list of trade symbols sold at this marketplace.
  // Upload current prices at this market to the db.
  // For each trade symbol, get the price at this marketplace.
  // for (final tradeSymbol in tradeSymbols) {}
  // For each trade symbol, get the price at the destination marketplace.
  // Sort by assumed profit.
  // If we don't have a destination price, assume 50th percentile.
  // Deals are then sorted by profit, and we take the best one.

  // If we don't have a percentile, match only export/import.
  // Picking at random from the matchable exports?
  // Or picking the shortest distance?
}
