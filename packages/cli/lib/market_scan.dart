import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

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
  MarketPrices marketPrices,
  Market market,
  TradeSymbol tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods = market.marketTradeGood(tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.sellPrice;
  }

  final recentSellPrice = marketPrices.recentSellPrice(
    tradeSymbol,
    marketSymbol: market.symbol,
  );
  if (recentSellPrice != null) {
    return recentSellPrice;
  }
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    return null;
  }
  final percentile = _percentileForTradeType(tradeType);
  return marketPrices.sellPriceAtPercentile(tradeSymbol, percentile);
}

/// Estimate the current purchase price of [tradeSymbol] at [market].
int? estimatePurchasePrice(
  MarketPrices marketPrices,
  Market market,
  TradeSymbol tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods = market.marketTradeGood(tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.purchasePrice;
  }
  final recentPurchasePrice = marketPrices.recentPurchasePrice(
    marketSymbol: market.symbol,
    tradeSymbol,
  );
  if (recentPurchasePrice != null) {
    return recentPurchasePrice;
  }
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    return null;
  }
  final percentile = _percentileForTradeType(tradeType);
  return marketPrices.purchasePriceAtPercentile(tradeSymbol, percentile);
}

/// A potential purchase opportunity.
@immutable
class BuyOpp {
  /// Create a new BuyOpp.
  const BuyOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
  });

  /// The symbol of the market where the good can be purchased.
  final String marketSymbol;

  /// The symbol of the good offered for purchase.
  final String tradeSymbol;

  /// The price of the good.
  final int price;
}

/// A potential sale opportunity.  Only public for testing.
@immutable
class SellOpp {
  /// Create a new SellOpp.
  const SellOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
    this.contractId,
    this.maxUnits,
  });

  /// The symbol of the market where the good can be sold.
  final String marketSymbol;

  /// The symbol of the good.
  final String tradeSymbol;

  /// The price of the good.
  final int price;

  /// Set to the contractId for contract deliveries.
  final String? contractId;

  /// The maximum number of units we can sell.
  /// This is only used for contract deliveries towards the very end of
  /// a contract.
  final int? maxUnits;
}

class _MarketScanBuilder {
  _MarketScanBuilder(MarketPrices marketPrices, {required this.topLimit})
      : _marketPrices = marketPrices;

  /// How many deals to keep track of per trade symbol.
  final int topLimit;
  final Map<String, List<BuyOpp>> buyOpps = {};
  final Map<String, List<SellOpp>> sellOpps = {};

  final MarketPrices _marketPrices;

  void _addBuyOpp(BuyOpp buy) {
    // Sort buys ascending so we remove the most expensive buy price.
    final buys = (buyOpps[buy.tradeSymbol] ?? [])
      ..add(buy)
      ..sort((a, b) => a.price.compareTo(b.price));
    if (buys.length > topLimit) {
      buys.removeLast();
    }
    buyOpps[buy.tradeSymbol] = buys;
  }

  void _addSellOpp(SellOpp sell) {
    // Sort sells decending so we remove the cheapest sell price.
    final sells = (sellOpps[sell.tradeSymbol] ?? [])
      ..add(sell)
      ..sort((a, b) => -a.price.compareTo(b.price));
    if (sells.length > topLimit) {
      sells.removeLast();
    }
    sellOpps[sell.tradeSymbol] = sells;
  }

  /// Record potential deals from the given historical market price.
  void visitMarketPrice(MarketPrice marketPrice) {
    final marketSymbol = marketPrice.waypointSymbol;
    final tradeSymbol = marketPrice.symbol;
    _addBuyOpp(
      BuyOpp(
        marketSymbol: marketSymbol,
        tradeSymbol: tradeSymbol,
        price: marketPrice.purchasePrice,
      ),
    );
    _addSellOpp(
      SellOpp(
        marketSymbol: marketSymbol,
        tradeSymbol: tradeSymbol,
        price: marketPrice.sellPrice,
      ),
    );
  }

  /// Record potential deals from the given market.
  void visitMarket(Market market) {
    for (final tradeSymbol in market.allTradeSymbols) {
      // See if the price data we have for this trade symbol
      // are in the top/bottom we've seen, if so, record them.
      final buyPrice =
          estimatePurchasePrice(_marketPrices, market, tradeSymbol);
      if (buyPrice == null) {
        // If we don't have buy data we won't have sell data either.
        continue;
      }
      _addBuyOpp(
        BuyOpp(
          marketSymbol: market.symbol,
          tradeSymbol: tradeSymbol.value,
          price: buyPrice,
        ),
      );
      _addSellOpp(
        SellOpp(
          marketSymbol: market.symbol,
          tradeSymbol: tradeSymbol.value,
          price: estimateSellPrice(_marketPrices, market, tradeSymbol)!,
        ),
      );
    }
  }
}

/// Represents a collection of buy and sell opportunities for a given set
/// of markets.
class MarketScan {
  MarketScan._({
    required Map<String, List<BuyOpp>> buyOpps,
    required Map<String, List<SellOpp>> sellOpps,
  })  : _buyOpps = Map.unmodifiable(buyOpps),
        _sellOpps = Map.unmodifiable(sellOpps);

  /// Create a new MarketScan for testing.
  @visibleForTesting
  MarketScan.test({
    required List<BuyOpp> buyOpps,
    required List<SellOpp> sellOpps,
  })  : _buyOpps = groupBy(buyOpps, (b) => b.tradeSymbol),
        _sellOpps = groupBy(sellOpps, (s) => s.tradeSymbol);

  /// Given a set of historical market prices, will collect the top N buy and
  /// sell opportunities for each trade symbol regardless of distance.
  factory MarketScan.fromMarketPrices(
    MarketPrices marketPrices, {
    bool Function(String waypointSymbol)? waypointFilter,
  }) {
    final builder = _MarketScanBuilder(marketPrices, topLimit: 5);
    for (final marketPrice in marketPrices.prices) {
      if (waypointFilter != null &&
          !waypointFilter(marketPrice.waypointSymbol)) {
        continue;
      }
      builder.visitMarketPrice(marketPrice);
    }
    return MarketScan._(buyOpps: builder.buyOpps, sellOpps: builder.sellOpps);
  }

  final Map<String, List<BuyOpp>> _buyOpps;
  final Map<String, List<SellOpp>> _sellOpps;

  /// The trade symbols for which we found opportunities.
  List<String> get tradeSymbols => _buyOpps.keys.toList();

  /// Lookup the buy opportunities for the given trade symbol.
  List<BuyOpp> buyOppsForTradeSymbol(String tradeSymbol) =>
      _buyOpps[tradeSymbol] ?? [];

  /// Lookup the sell opportunities for the given trade symbol.
  List<SellOpp> sellOppsForTradeSymbol(String tradeSymbol) =>
      _sellOpps[tradeSymbol] ?? [];
}
