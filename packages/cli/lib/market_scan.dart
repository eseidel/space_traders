import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// A potential purchase opportunity.
@immutable
class BuyOpp {
  /// Create a new BuyOpp.
  const BuyOpp(this.marketPrice);

  /// State of the market where this buy opportunity was found.
  final MarketPrice marketPrice;

  /// The symbol of the market where the good can be purchased.
  WaypointSymbol get marketSymbol => marketPrice.waypointSymbol;

  /// The symbol of the good offered for purchase.
  TradeSymbol get tradeSymbol => marketPrice.tradeSymbol;

  /// The price of the good.
  int get price => marketPrice.purchasePrice;
}

/// A potential sale opportunity.  Only public for testing.
@immutable
class SellOpp {
  /// Create a new SellOpp from a MarketPrice.
  SellOpp.fromMarketPrice(MarketPrice this.marketPrice)
      : marketSymbol = marketPrice.waypointSymbol,
        tradeSymbol = marketPrice.tradeSymbol,
        price = marketPrice.sellPrice,
        contractId = null,
        maxUnits = null;

  /// Create a new SellOpp from a contract.
  const SellOpp.fromContract({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
    required this.contractId,
    required this.maxUnits,
  }) : marketPrice = null;

  /// State of the market where this sell opportunity was found.
  final MarketPrice? marketPrice;

  /// The symbol of the market where the good can be sold.
  final WaypointSymbol marketSymbol;

  /// The symbol of the good offered for sold.
  final TradeSymbol tradeSymbol;

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
    bool Function(WaypointSymbol waypointSymbol)? waypointFilter,
  }) {
    final builder = _MarketScanBuilder(topLimit: 5);
    for (final marketPrice in marketPrices.prices) {
      if (waypointFilter != null &&
          !waypointFilter(marketPrice.waypointSymbol)) {
        continue;
      }
      builder.visitMarketPrice(marketPrice);
    }
    return MarketScan._(buyOpps: builder.buyOpps, sellOpps: builder.sellOpps);
  }

  final Map<TradeSymbol, List<BuyOpp>> _buyOpps;
  final Map<TradeSymbol, List<SellOpp>> _sellOpps;

  /// The trade symbols for which we found opportunities.
  List<TradeSymbol> get tradeSymbols => _buyOpps.keys.toList();

  /// Lookup the buy opportunities for the given trade symbol.
  List<BuyOpp> buyOppsForTradeSymbol(TradeSymbol tradeSymbol) =>
      _buyOpps[tradeSymbol] ?? [];

  /// Lookup the sell opportunities for the given trade symbol.
  List<SellOpp> sellOppsForTradeSymbol(TradeSymbol tradeSymbol) =>
      _sellOpps[tradeSymbol] ?? [];
}
