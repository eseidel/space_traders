import 'dart:math';

import 'package:types/config.dart';
import 'package:types/src/snapshot/price_snapshot.dart';
import 'package:types/types.dart';

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class MarketPriceSnapshot extends PriceSnapshot<TradeSymbol, MarketPrice> {
  /// Create a new price data collection.
  MarketPriceSnapshot(super.records);

  static int _sellPriceAscending(MarketPrice a, MarketPrice b) =>
      a.sellPrice.compareTo(b.sellPrice);
  static int _purchasePriceAscending(MarketPrice a, MarketPrice b) =>
      a.purchasePrice.compareTo(b.purchasePrice);

  /// Get the median price this good can be purchased for.
  int? medianPurchasePrice(TradeSymbol symbol) {
    final maybePrice = _priceAtPercentile(
      symbol,
      50,
      MarketTransactionType.PURCHASE,
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
    var index = pricesForSymbolSorted.indexWhere(
      (e) => e.sellPrice.compareTo(sellPrice) > 0,
    );
    // If we ran off the end, we know that the price is greater than all
    // the prices in the list. i.e. 100th percentile.
    if (index == -1) {
      index = pricesForSymbol.length;
    }
    return (index / pricesForSymbol.length * 100).round();
  }

  /// Get the median price for a trade good based on transaction type.
  int? medianPrice(TradeSymbol tradeSymbol, MarketTransactionType type) {
    return type == MarketTransactionType.SELL
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
      MarketTransactionType.SELL,
    );
    return maybePrice?.sellPrice;
  }

  MarketPrice? _priceAtPercentile(
    TradeSymbol symbol,
    int percentile,
    MarketTransactionType action,
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
    final compareTo = action == MarketTransactionType.PURCHASE
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
    return priceAt(
      marketSymbol,
      tradeSymbol,
      maxAge: maxAge,
      getNow: getNow,
    )?.sellPrice;
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
    return priceAt(
      marketSymbol,
      tradeSymbol,
      maxAge: maxAge,
      getNow: getNow,
    )?.purchasePrice;
  }
}
