import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';

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

  /// Create a deal from JSON.
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      sourceSymbol: json['sourceSymbol'] as String,
      destinationSymbol: json['destinationSymbol'] as String,
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
    );
  }

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

  /// Encode the deal as JSON.
  Map<String, dynamic> toJson() => {
        'sourceSymbol': sourceSymbol,
        'destinationSymbol': destinationSymbol,
        'tradeSymbol': tradeSymbol.toJson(),
        'purchasePrice': purchasePrice,
        'sellPrice': sellPrice,
      };
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

// Not sure where this blongs?
/// Returns a waypoint nearby which trades the good.
/// This is not necessarily the nearest, but could be improved to be.
Future<Waypoint?> nearbyMarketWhichTrades(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Waypoint start,
  String tradeSymbol, {
  int maxJumps = 1,
}) async {
  if (start.hasMarketplace) {
    final startMarket = await marketCache.marketForSymbol(start.symbol);
    if (startMarket!.allowsTradeOf(tradeSymbol)) {
      return start;
    }
  }
  await for (final waypoint in waypointsInJumpRadius(
    systemsCache: systemsCache,
    waypointCache: waypointCache,
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    final market = await marketCache.marketForSymbol(waypoint.symbol);
    if (market != null && market.allowsTradeOf(tradeSymbol)) {
      return waypoint;
    }
  }
  return null;
}
