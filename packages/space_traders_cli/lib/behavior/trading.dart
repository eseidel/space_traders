import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';

/// Record of a possible arbitrage opportunity.
// This should also include expected cost of fuel and cost of time.
class Deal {
  /// Create a new deal.
  Deal({
    required this.sourceSymbol,
    required this.destinationSymbol,
    required this.tradeSymbol,
    required this.purchasePrice,
    required this.sellPrice,
  });

  /// The trade symbol that we're selling.
  final TradeSymbol tradeSymbol;

  /// The symbol of the market we're buying from.
  final String sourceSymbol;

  /// The symbol of the market we're selling to.
  final String destinationSymbol;

  /// The price we're buying at per unit.
  final int purchasePrice;

  /// The price we're selling at per unit.
  final int sellPrice;
  // Also should take fuel costs into account.
  // And possibly time?

  // Profit depends on route taken, so this likely does not
  // belong here.
  /// The profit we'll make on this deal per unit.
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
  Market market,
  String tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods =
      market.tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.sellPrice;
  }

  final recentSellPrice = priceData.recentSellPrice(
    marketSymbol: market.symbol,
    tradeSymbol: tradeSymbol,
  );
  if (recentSellPrice != null) {
    return recentSellPrice;
  }
  // logger.info(
  //   'No recent sell price for ${tradeSymbol.value} at ${market.symbol}',
  // );
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    logger.detail('${market.symbol} does not trade $tradeSymbol');
    return null;
  }
  // print('Looking up ${tradeSymbol.value} ${market.symbol} $tradeType');
  final percentile = _percentileForTradeType(tradeType);
  // logger
  //  .info('Looking up sell price for $tradeSymbol at $percentile percentile');
  return priceData.sellPriceAtPercentile(tradeSymbol, percentile);
}

/// Estimate the current purchase price of [tradeSymbol] at [market].
int? estimatePurchasePrice(
  PriceData priceData,
  Market market,
  String tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods =
      market.tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.purchasePrice;
  }
  final recentPurchasePrice = priceData.recentPurchasePrice(
    marketSymbol: market.symbol,
    tradeSymbol: tradeSymbol,
  );
  if (recentPurchasePrice != null) {
    return recentPurchasePrice;
  }
  // logger.info(
  //   'No recent purchase price for ${tradeSymbol.value} at ${market.symbol}',
  // );
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    logger.detail('${market.symbol} does not trade $tradeSymbol');
    return null;
  }
  // print('Looking up ${tradeSymbol.value} ${market.symbol} $tradeType');
  final percentile = _percentileForTradeType(tradeType);
  return priceData.purchasePriceAtPercentile(tradeSymbol, percentile);
}

/// Enumerate all possible deals that could be made between [purchaseMarket] and
/// [otherMarkets].
Iterable<Deal> enumeratePossibleDeals(
  PriceData priceData,
  Market purchaseMarket,
  List<Market> otherMarkets,
) sync* {
  for (final otherMarket in otherMarkets) {
    for (final sellSymbol in otherMarket.allTradeSymbols) {
      final sellPrice =
          estimateSellPrice(priceData, otherMarket, sellSymbol.value);
      if (sellPrice == null) {
        continue;
      }
      for (final purchaseSymbol in purchaseMarket.allTradeSymbols) {
        if (sellSymbol != purchaseSymbol) {
          continue;
        }
        final purchasePrice = estimatePurchasePrice(
          priceData,
          purchaseMarket,
          purchaseSymbol.value,
        );
        if (purchasePrice == null) {
          // We're asking about a good that is not a market we have a ship at
          // and we don't have enough pricing data to estimate a price.
          continue;
        }
        yield Deal(
          sourceSymbol: purchaseMarket.symbol,
          tradeSymbol: sellSymbol,
          destinationSymbol: otherMarket.symbol,
          purchasePrice: purchasePrice,
          sellPrice: sellPrice,
        );
      }
    }
  }
}

/// Describe a [deal] in a human-readable way.
String describeDeal(Deal deal) {
  final sign = deal.profit > 0 ? '+' : '';
  final profitPercent = (deal.profit / deal.purchasePrice) * 100;
  final profitCreditsString = '$sign${creditsString(deal.profit)}'.padLeft(6);
  final profitPercentString = '${profitPercent.toStringAsFixed(0)}%';
  final profitString = '$profitCreditsString ($profitPercentString)';
  final coloredProfitString = deal.profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  return '${deal.tradeSymbol.value.padRight(18)} '
      ' ${deal.sourceSymbol} ${creditsString(deal.purchasePrice).padLeft(6)} '
      '-> '
      '${deal.destinationSymbol} ${creditsString(deal.sellPrice).padLeft(6)} '
      '$coloredProfitString';
}

/// Log proposed [deals] to the console.
void logDeals(List<Deal> deals) {
  final headers = [
    'Symbol'.padRight(18),
    'Source'.padRight(18),
    'Dest'.padRight(18),
    'Profit'.padRight(18),
  ];
  logger.info(headers.join(' '));
  for (final deal in deals) {
    logger.info(describeDeal(deal));
  }
}

/// Find the best deal that can be made from [currentWaypoint].
Deal? findBestDealFromWaypoint(
  PriceData priceData,
  Ship ship,
  Waypoint currentWaypoint,
  List<Market> markets, {
  int minimumProfitPer = 0,
}) {
  // Fetch all marketplace data
  final localMarket =
      markets.firstWhere((m) => m.symbol == currentWaypoint.symbol);
  final otherMarkets =
      markets.where((m) => m.symbol != localMarket.symbol).toList();

  final deals = enumeratePossibleDeals(priceData, localMarket, otherMarkets);
  final sortedDeals = deals.sorted((a, b) => a.profit.compareTo(b.profit));
  // logDeals(sortedDeals);
  final bestDeal = sortedDeals.lastOrNull;
  // Currently we don't account for fuel, so have an minimum expected
  // profit instead.
  if (bestDeal == null || bestDeal.profit <= minimumProfitPer) {
    final profitString =
        bestDeal == null ? null : creditsString(bestDeal.profit);
    shipInfo(
      ship,
      '0 of ${sortedDeals.length} deals profitable '
      'from ${currentWaypoint.symbol}, best: $profitString',
    );
    return null;
  }
  final bestCreditsString = '+${creditsString(bestDeal.profit)}';
  shipInfo(
      ship,
      '${sortedDeals.length} deals found from '
      '${currentWaypoint.symbol} best: ${bestCreditsString.padLeft(6)}');
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

/// Describe a [deal] in a human-readable way.
String dealDescription(Deal deal, {int units = 1}) {
  final profitString =
      lightGreen.wrap('+${creditsString(deal.profit * units)}');
  return 'Deal ($profitString): ${deal.tradeSymbol} '
      '${creditsString(deal.purchasePrice)} @ ${deal.sourceSymbol} '
      '-> ${creditsString(deal.sellPrice)} @ ${deal.destinationSymbol} '
      'profit: ${creditsString(deal.profit)} per unit ';
}

/// Log a [deal] to the console.
void logDeal(Ship ship, Deal deal) {
  shipInfo(ship, dealDescription(deal, units: ship.availableSpace));
}
