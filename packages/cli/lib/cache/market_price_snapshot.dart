import 'dart:math';

import 'package:cli/cache/price_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';

double _expectedPercentageChangeByVolume(int tradeVolume) {
  if (tradeVolume < 10) {
    return 1;
  }
  if (tradeVolume < 25) {
    return 0.50;
  }
  if (tradeVolume < 50) {
    return 0.30;
  }
  if (tradeVolume < 100) {
    return 0.10;
  }
  return 0;
}

/// Predict the next price based on the current price and the trade volume.
int expectedPriceMovement({
  required int currentPrice,
  required int tradeVolume,
  required int units,
  // required int medianPrice,
  required MarketTransactionTypeEnum action,
}) {
  // I'm confident that price movements are quadratic in nature.
  // When I've attempted to fit the curve across multiple repeated buys,
  // they've fit very well to a quadratic curve.
  // Including buying units below the set price *decreasing* the price.
  // However I don't know how to turn that into a function to predict the
  // next price, especially across multiple different markets and trade goods.
  // These price changes most notably affect "shallow" markets, where the
  // trade volume is low.
  // I don't have good data for tradeVolume = 1, it likely moves faster?
  final sign = action == MarketTransactionTypeEnum.PURCHASE ? 1 : -1;
  final percentChange = _expectedPercentageChangeByVolume(tradeVolume);
  return sign * (percentChange * currentPrice).round();
}

/// Add prediction capabilities to MarketPrice
extension MarketPricePredications on MarketPrice {
  /// Predict the price of buying the Nth unit of this good.
  /// Unit is a 0-based index of the unit being purchased.
  int predictPurchasePriceForUnit(int unit) {
    var predictedPrice = purchasePrice;
    final batchCount = unit ~/ tradeVolume;
    for (var i = 0; i < batchCount; i++) {
      final expectedMovement = expectedPriceMovement(
        currentPrice: predictedPrice,
        tradeVolume: tradeVolume,
        units: unit,
        action: MarketTransactionTypeEnum.PURCHASE,
      );
      predictedPrice += expectedMovement;
    }
    return predictedPrice;
  }

  /// Predict the number of units that can be purchased for [maxSpend].
  int predictUnitsPurchasableFor({
    required int maxSpend,
    required int maxUnits,
  }) {
    var units = 0;
    var totalCost = 0;
    // This is not efficient, but works for now.
    while (totalCost < maxSpend) {
      if (units >= maxUnits) {
        break;
      }
      totalCost += predictPurchasePriceForUnit(units);
      units++;
    }
    return units;
  }

  /// Predict the price of buying the Nth unit of this good.
  /// Unit is a 0-based index of the unit being purchased.
  int predictSellPriceForUnit(int unit) {
    var predictedPrice = sellPrice;
    final batchCount = unit ~/ tradeVolume;
    for (var i = 0; i < batchCount; i++) {
      final expectedMovement = expectedPriceMovement(
        currentPrice: predictedPrice,
        tradeVolume: tradeVolume,
        units: unit,
        action: MarketTransactionTypeEnum.SELL,
      );
      predictedPrice += expectedMovement;
    }
    return predictedPrice;
  }
}

/// Logic for predicting the next price for a market.
extension MarketPricePredictions on MarketPrice {
  /// Predict the total price of buying [units] of this good.
  int totalPurchasePriceFor(int units) {
    var totalPrice = 0;
    for (var i = 0; i < units; i++) {
      totalPrice += predictPurchasePriceForUnit(i);
    }
    return totalPrice;
  }

  /// Predict the total price of buying [units] of this good.
  int totalSellPriceFor(int units) {
    var totalPrice = 0;
    for (var i = 0; i < units; i++) {
      totalPrice += predictSellPriceForUnit(i);
    }
    return totalPrice;
  }
}

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class MarketPriceSnapshot extends PriceSnapshot<TradeSymbol, MarketPrice> {
  /// Create a new price data collection.
  MarketPriceSnapshot(super.records);

  /// Load the price data from the cache.
  static Future<MarketPriceSnapshot> loadAll(Database db) async {
    final prices = await db.allMarketPrices();
    return MarketPriceSnapshot(prices.toList());
  }

  /// Load the price data for a single system from the cache.
  static Future<MarketPriceSnapshot> loadOneSystem(
    Database db,
    SystemSymbol system,
  ) async {
    final prices = await db.marketPricesInSystem(system);
    return MarketPriceSnapshot(prices.toList());
  }

  static int _sellPriceAscending(MarketPrice a, MarketPrice b) =>
      a.sellPrice.compareTo(b.sellPrice);
  static int _purchasePriceAscending(MarketPrice a, MarketPrice b) =>
      a.purchasePrice.compareTo(b.purchasePrice);

  /// Get the median price this good can be purchased for.
  int? medianPurchasePrice(TradeSymbol symbol) {
    final maybePrice = _priceAtPercentile(
      symbol,
      50,
      MarketTransactionTypeEnum.PURCHASE,
    );
    return maybePrice?.purchasePrice;
  }

  /// Get the percentile for the sell price (you sell to them) of a trade good.
  int? percentileForSellPrice(TradeSymbol symbol, int sellPrice) {
    const compareTo = _sellPriceAscending;
    final pricesForSymbol = pricesFor(symbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    // Find the first index where the sorted price is greater than the price
    // being compared.
    var index = pricesForSymbolSorted
        .indexWhere((e) => e.sellPrice.compareTo(sellPrice) > 0);
    // If we ran off the end, we know that the price is greater than all
    // the prices in the list. i.e. 100th percentile.
    if (index == -1) {
      index = pricesForSymbol.length;
    }
    return (index / pricesForSymbol.length * 100).round();
  }

  /// Get the median price for a trade good based on transaction type.
  int? medianPrice(TradeSymbol tradeSymbol, MarketTransactionTypeEnum type) {
    return type == MarketTransactionTypeEnum.SELL
        ? medianSellPrice(tradeSymbol)
        : medianPurchasePrice(tradeSymbol);
  }

  /// Get the median sell price for a trade good.
  int? medianSellPrice(TradeSymbol symbol) => sellPriceAtPercentile(symbol, 50);

  /// Get the percentile sell price for a trade good.
  /// [percentile] must be between 0 and 100.
  int? sellPriceAtPercentile(TradeSymbol symbol, int percentile) {
    final maybePrice = _priceAtPercentile(
      symbol,
      percentile,
      MarketTransactionTypeEnum.SELL,
    );
    return maybePrice?.sellPrice;
  }

  MarketPrice? _priceAtPercentile(
    TradeSymbol symbol,
    int percentile,
    MarketTransactionTypeEnum action,
  ) {
    if (percentile > 100 || percentile < 0) {
      throw ArgumentError.value(
        percentile,
        'percentile',
        'Percentile must be between 0 and 100',
      );
    }
    final pricesForSymbol = pricesFor(symbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    final compareTo = action == MarketTransactionTypeEnum.PURCHASE
        ? _purchasePriceAscending
        : _sellPriceAscending;
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    // Make sure that 100th percentile doesn't go out of bounds.
    // TODO(eseidel): This doesn't match postgres' percentile_disc.
    // percentile_disc will round up to the next index if the percentile
    // doesn't match an exact index.
    final index = min(
      pricesForSymbolSorted.length * percentile ~/ 100,
      pricesForSymbolSorted.length - 1,
    );
    return pricesForSymbolSorted[index];
  }

  /// Most recent price a good can be sold to the market for.
  /// [marketSymbol] is the symbol for the market.
  /// [tradeSymbol] is the symbol for the trade good.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentSellPrice(
    TradeSymbol tradeSymbol, {
    required WaypointSymbol marketSymbol,
    Duration maxAge = defaultMaxAge,
    DateTime Function() getNow = defaultGetNow,
  }) {
    return priceAt(marketSymbol, tradeSymbol, maxAge: maxAge, getNow: getNow)
        ?.sellPrice;
  }

  /// The most recent price can be purchased from the market.
  /// [marketSymbol] is the symbol for the market.
  /// [tradeSymbol] is the symbol for the trade good.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentPurchasePrice(
    TradeSymbol tradeSymbol, {
    required WaypointSymbol marketSymbol,
    Duration maxAge = defaultMaxAge,
    DateTime Function() getNow = defaultGetNow,
  }) {
    return priceAt(marketSymbol, tradeSymbol, maxAge: maxAge, getNow: getNow)
        ?.purchasePrice;
  }
}

/// Record market data silently.
Future<void> recordMarketData(
  Database db,
  Market market, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final prices = market.tradeGoods
      .map(
        (tradeGood) => MarketPrice.fromMarketTradeGood(
          tradeGood,
          market.waypointSymbol,
          getNow(),
        ),
      )
      .toList();
  if (prices.isEmpty) {
    logger.warn('No prices for ${market.symbol}!');
  }
  for (final price in prices) {
    await db.upsertMarketPrice(price);
  }
}
