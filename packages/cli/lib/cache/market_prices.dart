import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/file.dart';
import 'package:meta/meta.dart';

/// default max age for "recent" prices is 3 days
const defaultMaxAge = Duration(days: 3);

// {"waypointSymbol": "X1-ZS60-53675E", "symbol": "IRON_ORE", "supply":
// "ABUNDANT", "purchasePrice": 6, "sellPrice": 4, "tradeVolume": 1000,
// "timestamp": "2023-05-14T21:52:56.530126100+00:00"}
/// Transaction data for a single trade symbol at a single waypoint.
@immutable
class MarketPrice {
  /// Create a new price record.
  const MarketPrice({
    required this.waypointSymbol,
    required this.symbol,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    required this.tradeVolume,
    required this.timestamp,
  });

  /// Create a new price record from a market trade good.
  MarketPrice.fromMarketTradeGood(MarketTradeGood good, this.waypointSymbol)
      : symbol = good.symbol,
        supply = good.supply,
        purchasePrice = good.purchasePrice,
        sellPrice = good.sellPrice,
        tradeVolume = good.tradeVolume,
        timestamp = DateTime.now();

  MarketPrice._compareOnly({this.sellPrice = 0})
      : waypointSymbol = WaypointSymbol.fromString('A-B-C'),
        symbol = '',
        supply = MarketTradeGoodSupplyEnum.ABUNDANT,
        tradeVolume = 0,
        purchasePrice = 0,
        timestamp = DateTime.now();

  /// Create a new price record from a json map.
  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    // Server started sending tradeVolume as a string recently, until that
    // is fixed, need to handle it here.
    final value = json['tradeVolume'];
    final tradeVolume = value is int ? value : int.parse(value as String);
    return MarketPrice(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      symbol: json['symbol'] as String,
      supply: MarketTradeGoodSupplyEnum.fromJson(json['supply'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      tradeVolume: tradeVolume,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Serialize Price as a json map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'waypointSymbol': waypointSymbol.toJson(),
      'symbol': symbol,
      'supply': supply.toJson(),
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'tradeVolume': tradeVolume,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  /// The waypoint of the market where this price was recorded.
  final WaypointSymbol waypointSymbol;

  /// The symbol of the trade good.
  // TODO(eseidel): Change to TradeSymbol
  final String symbol;

  /// The trade symbol of the trade good.
  TradeSymbol get tradeSymbol => TradeSymbol.fromJson(symbol)!;

  /// The supply level of the trade good.
  final MarketTradeGoodSupplyEnum supply;

  /// The price at which this good can be purchased from the market.
  final int purchasePrice;

  /// The price at which this good can be sold to the market.
  final int sellPrice;

  /// The trade volume of the trade good.
  final int tradeVolume;

  /// The timestamp of the price record.
  final DateTime timestamp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketPrice &&
          runtimeType == other.runtimeType &&
          waypointSymbol == other.waypointSymbol &&
          symbol == other.symbol &&
          supply == other.supply &&
          purchasePrice == other.purchasePrice &&
          sellPrice == other.sellPrice &&
          tradeVolume == other.tradeVolume &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      waypointSymbol.hashCode ^
      symbol.hashCode ^
      supply.hashCode ^
      purchasePrice.hashCode ^
      sellPrice.hashCode ^
      tradeVolume.hashCode ^
      timestamp.hashCode;
}

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class MarketPrices extends JsonListStore<MarketPrice> {
  /// Create a new price data collection.
  MarketPrices(
    super.prices, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/prices.json';

  /// Load the price data from the cache.
  // ignore: prefer_constructors_over_static_methods
  static MarketPrices load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final prices = JsonListStore.load<MarketPrice>(
          fs,
          path,
          MarketPrice.fromJson,
        ) ??
        [];
    return MarketPrices(prices, fs: fs, path: path);
  }

  /// Get the count of unique waypoints.
  int get waypointCount {
    final waypoints = <WaypointSymbol>{};
    for (final price in entries) {
      waypoints.add(price.waypointSymbol);
    }
    return waypoints.length;
  }

  /// Get the raw pricing data.
  List<MarketPrice> get prices => List.unmodifiable(entries);

  List<MarketPrice> get _prices => entries;

  /// Add new prices to the price data.
  Future<void> addPrices(
    List<MarketPrice> newPrices, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    // Go through the list, see if we already have a price for this pair
    // if so, replace it, otherwise add to the end?
    // Probably this should add them to a separate buffer, which is then
    // compacted into the main list at some specific point.
    for (final newPrice in newPrices) {
      // logger.detail('Recording price: ${describePrice(newPrice)}');
      // This doesn't account for duplicates.
      final index = _prices.indexWhere(
        (element) =>
            element.waypointSymbol == newPrice.waypointSymbol &&
            element.symbol == newPrice.symbol,
      );

      if (getNow().isBefore(newPrice.timestamp)) {
        logger.warn('Bogus timestamp on price: ${newPrice.timestamp}');
        continue;
      }

      if (index >= 0) {
        // This date logic is necessary to make sure we don't replace
        // more recent local prices with older server data.
        final existingPrice = _prices[index];
        if (newPrice.timestamp.isBefore(existingPrice.timestamp)) {
          continue;
        }
        // If the new price is newer than the existing price, replace it.
        _prices[index] = newPrice;
      } else {
        _prices.add(newPrice);
      }
    }
    save();
  }

  static int _sellPriceAcending(MarketPrice a, MarketPrice b) =>
      a.sellPrice.compareTo(b.sellPrice);
  static int _purchasePriceAcending(MarketPrice a, MarketPrice b) =>
      a.purchasePrice.compareTo(b.purchasePrice);

  /// Get the median price this good can be purchased for.
  int? medianPurchasePrice(TradeSymbol symbol) =>
      purchasePriceAtPercentile(symbol, 50);

  /// Get the percentile purchase price (price you can buy at) for a trade good.
  /// [percentile] must be between 0 and 100.
  int? purchasePriceAtPercentile(TradeSymbol symbol, int percentile) {
    final maybePrice = _priceAtPercentile(
      symbol,
      percentile,
      MarketTransactionTypeEnum.PURCHASE,
    );
    return maybePrice?.purchasePrice;
  }

  /// Get the percentile for the sell price (you sell to them) of a trade good.
  int? percentileForSellPrice(TradeSymbol symbol, int sellPrice) {
    const compareTo = _sellPriceAcending;
    final price = MarketPrice._compareOnly(sellPrice: sellPrice);
    final pricesForSymbol = pricesFor(symbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    // Find the first index where the sorted price is greater than the price
    // being compared.
    var index =
        pricesForSymbolSorted.indexWhere((e) => compareTo(e, price) > 0);
    // If we ran off the end, we know that the price is greater than all
    // the prices in the list. i.e. 100th percentile.
    if (index == -1) {
      index = pricesForSymbol.length;
    }
    return (index / pricesForSymbol.length * 100).round();
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

  /// Returns all known prices for a trade good,
  /// optionally restricted to a specific waypoint.
  Iterable<MarketPrice> pricesFor(
    TradeSymbol tradeSymbol, {
    WaypointSymbol? marketSymbol,
  }) {
    final prices = _prices.where((e) => e.symbol == tradeSymbol.value);
    if (marketSymbol == null) {
      return prices;
    }
    return prices.where((e) => e.waypointSymbol == marketSymbol);
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
        ? _purchasePriceAcending
        : _sellPriceAcending;
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    // Make sure that 100th percentile doesn't go out of bounds.
    final index = min(
      pricesForSymbolSorted.length * percentile ~/ 100,
      pricesForSymbolSorted.length - 1,
    );
    return pricesForSymbolSorted[index];
  }

  /// Returns all known prices for a given market.
  List<MarketPrice> pricesAtMarket(WaypointSymbol marketSymbol) {
    return _prices.where((e) => e.waypointSymbol == marketSymbol).toList();
  }

  /// Returns true if there is recent market data for a given market.
  /// Does not check if the passed in market is a valid market.
  bool hasRecentMarketData(
    WaypointSymbol marketSymbol, {
    Duration maxAge = defaultMaxAge,
  }) {
    final prices = pricesAtMarket(marketSymbol);
    if (prices.isEmpty) {
      return false;
    }
    final sortedPrices = prices.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return DateTime.timestamp().difference(sortedPrices.last.timestamp) <
        maxAge;
  }

  /// Most recent price a good can be sold to the market for.
  /// [marketSymbol] is the symbol for the market.
  /// [tradeSymbol] is the symbol for the trade good.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentSellPrice(
    TradeSymbol tradeSymbol, {
    required WaypointSymbol marketSymbol,
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForSymbol = pricesFor(tradeSymbol, marketSymbol: marketSymbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    final pricesForSymbolSorted = pricesForSymbol.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pricesForSymbolSorted.last.timestamp.difference(DateTime.now()) >
        maxAge) {
      return null;
    }
    return pricesForSymbolSorted.last.sellPrice;
  }

  /// The most recent price can be purchased from the market.
  /// [marketSymbol] is the symbol for the market.
  /// [tradeSymbol] is the symbol for the trade good.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentPurchasePrice(
    TradeSymbol tradeSymbol, {
    required WaypointSymbol marketSymbol,
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForSymbol = pricesFor(
      tradeSymbol,
      marketSymbol: marketSymbol,
    );
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    final pricesForSymbolSorted = pricesForSymbol.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (pricesForSymbolSorted.last.timestamp.difference(DateTime.now()) >
        maxAge) {
      return null;
    }
    return pricesForSymbolSorted.last.purchasePrice;
  }
}

/// Record market data and log the result.
/// Returns the market.
/// This is the prefered way to get the local Market.
Future<Market> recordMarketDataIfNeededAndLog(
  MarketPrices marketPrices,
  MarketCache marketCache,
  Ship ship,
  WaypointSymbol marketSymbol, {
  Duration maxAge = const Duration(minutes: 5),
}) async {
  if (ship.waypointSymbol != marketSymbol) {
    throw ArgumentError.value(
      marketSymbol,
      'marketSymbol',
      '${ship.symbol} is not at $marketSymbol, ${ship.waypointSymbol}.',
    );
  }
  // If we have market data more recent than maxAge, don't bother refreshing.
  // This prevents ships from constantly refreshing the same data.
  if (marketPrices.hasRecentMarketData(marketSymbol, maxAge: maxAge)) {
    final market = await marketCache.marketForSymbol(marketSymbol);
    return market!;
  }
  final market = await marketCache.marketForSymbol(
    ship.waypointSymbol,
    forceRefresh: true,
  );
  await recordMarketDataAndLog(marketPrices, market!, ship);
  return market;
}

/// Record market data and log the result.
Future<void> recordMarketDataAndLog(
  MarketPrices marketPrices,
  Market market,
  Ship ship,
) async {
  await recordMarketData(marketPrices, market);
  // Powershell needs an extra space after the emoji.
  shipInfo(ship, '✍️  market data @ ${market.symbol}');
}

/// Record market data silently.
Future<void> recordMarketData(MarketPrices marketPrices, Market market) async {
  final prices = market.tradeGoods
      .map((g) => MarketPrice.fromMarketTradeGood(g, market.waypointSymbol))
      .toList();
  if (prices.isEmpty) {
    logger.warn('No prices for ${market.symbol}!');
  }
  await marketPrices.addPrices(prices);
}
