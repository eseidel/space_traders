import 'package:cli/cache/market_price_snapshot.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

class _MarketScanBuilder {
  _MarketScanBuilder({required this.topLimit});

  /// How many deals to keep track of per trade symbol.
  final int topLimit;
  final Map<TradeSymbol, List<BuyOpp>> buyOpps = {};
  final Map<TradeSymbol, List<SellOpp>> sellOpps = {};

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
    _addBuyOpp(BuyOpp(marketPrice));
    _addSellOpp(SellOpp.fromMarketPrice(marketPrice));
  }
}

/// Represents a collection of buy and sell opportunities for a given set
/// of markets.
class MarketScan {
  MarketScan._({
    required Map<TradeSymbol, List<BuyOpp>> buyOpps,
    required Map<TradeSymbol, List<SellOpp>> sellOpps,
    required this.description,
  })  : _buyOpps = Map.unmodifiable(buyOpps),
        _sellOpps = Map.unmodifiable(sellOpps);

  /// Create a new MarketScan for testing.
  @visibleForTesting
  MarketScan.test({
    required List<BuyOpp> buyOpps,
    required List<SellOpp> sellOpps,
  })  : _buyOpps = groupBy(buyOpps, (b) => b.tradeSymbol),
        _sellOpps = groupBy(sellOpps, (s) => s.tradeSymbol),
        description = 'test';

  /// Given a set of historical market prices, will collect the top N buy and
  /// sell opportunities for each trade symbol regardless of distance.
  factory MarketScan.fromMarketPrices(
    MarketPriceSnapshot marketPrices, {
    required String description,
    bool Function(WaypointSymbol waypointSymbol)? waypointFilter,
    int opportunitiesPerTradeSymbol = 5,
  }) {
    final builder = _MarketScanBuilder(topLimit: opportunitiesPerTradeSymbol);
    for (final marketPrice in marketPrices.prices) {
      if (waypointFilter != null &&
          !waypointFilter(marketPrice.waypointSymbol)) {
        continue;
      }
      builder.visitMarketPrice(marketPrice);
    }
    return MarketScan._(
      buyOpps: builder.buyOpps,
      sellOpps: builder.sellOpps,
      description: description,
    );
  }

  final Map<TradeSymbol, List<BuyOpp>> _buyOpps;
  final Map<TradeSymbol, List<SellOpp>> _sellOpps;

  /// A description of how this market scan was created.
  final String description;

  /// The trade symbols for which we found opportunities.
  Set<TradeSymbol> get tradeSymbols => _buyOpps.keys.toSet();

  /// Lookup the buy opportunities for the given trade symbol.
  List<BuyOpp> buyOppsForTradeSymbol(TradeSymbol tradeSymbol) =>
      _buyOpps[tradeSymbol] ?? [];

  /// Lookup the sell opportunities for the given trade symbol.
  List<SellOpp> sellOppsForTradeSymbol(TradeSymbol tradeSymbol) =>
      _sellOpps[tradeSymbol] ?? [];
}
