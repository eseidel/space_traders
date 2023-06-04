import 'dart:convert';
import 'dart:math';

import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

/// default max age for "recent" prices is 3 days
const defaultMaxAge = Duration(days: 3);

// {"waypointSymbol": "X1-ZS60-53675E", "symbol": "IRON_ORE", "supply":
// "ABUNDANT", "purchasePrice": 6, "sellPrice": 4, "tradeVolume": 1000,
// "timestamp": "2023-05-14T21:52:56.530126100+00:00"}
/// Transaction data for a single trade symbol at a single waypoint.
class Price {
  /// Create a new price record.
  Price({
    required this.waypointSymbol,
    required this.symbol,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    required this.tradeVolume,
    required this.timestamp,
  });

  /// Create a new price record from a market trade good.
  Price.fromMarketTradeGood(MarketTradeGood good, this.waypointSymbol)
      : symbol = good.symbol,
        supply = good.supply,
        purchasePrice = good.purchasePrice,
        sellPrice = good.sellPrice,
        tradeVolume = good.tradeVolume,
        timestamp = DateTime.now();

  Price._compareOnly({this.purchasePrice = 0, this.sellPrice = 0})
      : waypointSymbol = '',
        symbol = '',
        supply = MarketTradeGoodSupplyEnum.ABUNDANT,
        tradeVolume = 0,
        timestamp = DateTime.now();

  /// Create a new price record from a json map.
  factory Price.fromJson(Map<String, dynamic> json) {
    // Server started sending tradeVolume as a string recently, until that
    // is fixed, need to handle it here.
    final value = json['tradeVolume'];
    final tradeVolume = value is int ? value : int.parse(value as String);
    return Price(
      waypointSymbol: json['waypointSymbol'] as String,
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
      'waypointSymbol': waypointSymbol,
      'symbol': symbol,
      'supply': supply.toJson(),
      'purchasePrice': purchasePrice,
      'sellPrice': sellPrice,
      'tradeVolume': tradeVolume,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Price{waypointSymbol: $waypointSymbol, symbol: $symbol, '
        'supply: $supply, purchasePrice: $purchasePrice, '
        'sellPrice: $sellPrice, tradeVolume: $tradeVolume, '
        'timestamp: $timestamp}';
  }

  /// The waypoint of the market where this price was recorded.
  final String waypointSymbol;

  /// The symbol of the trade good.
  final String symbol;

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
}

/// A collection of price records.
// Could consider sharding this by system if it gets too big.
class PriceData {
  /// Create a new price data collection.
  PriceData(
    List<Price> prices, {
    required FileSystem fs,
    this.cacheFilePath = defaultCacheFilePath,
  })  : _prices = prices,
        _fs = fs;

  // Eventually we should keep our own data and not use the global data.
  /// Url from which to fetch the global price data.
  static const String defaultUrl = 'https://st.feba66.de/prices';

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'prices.json';

  // This might not actually be true!  I've never seen a 0 in the data.
  // These may contain 0s and duplicates, best to access it through one
  // of the accessors which knows how to filter.
  final List<Price> _prices;

  /// The path to the cache file.
  final String cacheFilePath;

  /// The file system to use.
  final FileSystem _fs;

  /// Get the count of Price records.
  int get count => _prices.length;

  /// Get the count of unique waypoints.
  int get waypointCount {
    final waypoints = <String>{};
    for (final price in _prices) {
      waypoints.add(price.waypointSymbol);
    }
    return waypoints.length;
  }

  /// Get the raw pricing data.  You probably don't want this as it
  /// will be unfiltered and may contain duplicates and zero values.
  List<Price> get rawPrices => _prices;

  static List<Price> _parsePrices(String prices) {
    final parsed = jsonDecode(prices) as List<dynamic>;
    return parsed
        .map<Price>((e) => Price.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static PriceData? _loadPricesCache(FileSystem fs, String cacheFilePath) {
    final pricesFile = fs.file(cacheFilePath);
    if (pricesFile.existsSync()) {
      return PriceData(
        _parsePrices(pricesFile.readAsStringSync()),
        fs: fs,
        cacheFilePath: cacheFilePath,
      );
    }
    return null;
  }

  /// Save the price data to the cache.
  Future<void> save() async {
    await _fs.file(cacheFilePath).writeAsString(jsonEncode(_prices));
  }

  /// Load the price data from the cache or from the url.
  static Future<PriceData> load(
    FileSystem fs, {
    String? cacheFilePath,
    String? url,
    bool updateFromServer = false,
  }) async {
    final uri = Uri.parse(url ?? defaultUrl);
    final filePath = cacheFilePath ?? defaultCacheFilePath;
    // Try to load prices.json.  If it does not exist, pull down and cache
    // from the url.
    final fromCache = _loadPricesCache(fs, filePath);
    if (fromCache != null) {
      if (!updateFromServer) {
        return fromCache;
      }
    } else {
      logger.info('Failed to load prices from cache, fetching from $uri');
    }

    // We could mock http here.
    try {
      final response = await http.get(uri);
      final serverPrices = _parsePrices(response.body);
      if (fromCache == null) {
        final data = PriceData(serverPrices, fs: fs, cacheFilePath: filePath);
        await data.save();
        return data;
      }
      logger.info('Updating ${serverPrices.length} prices from server.');
      await fromCache.addPrices(serverPrices);
    } catch (e) {
      logger.warn('Failed to fetch prices from $uri: $e');
    }
    // fromCache can still be null if we failed to load from cache and
    // failed to load from server.
    return fromCache ?? PriceData([], fs: fs, cacheFilePath: filePath);
  }

  /// Add new prices to the price data.
  Future<void> addPrices(List<Price> newPrices) async {
    // Go through the list, see if we already have a price for this pair
    // if so, replace it, otherwise add to the end?
    // Probably this should add them to a separate buffer, which is then
    // compacted into the main list at some specific point.
    for (final newPrice in newPrices) {
      // This doesn't account for duplicates.
      final index = _prices.indexWhere(
        (element) =>
            element.waypointSymbol == newPrice.waypointSymbol &&
            element.symbol == newPrice.symbol,
      );
      if (index >= 0) {
        _prices[index] = newPrice;
      } else {
        _prices.add(newPrice);
      }
    }
    await save();
  }

  static int _sellPriceAcending(Price a, Price b) =>
      a.sellPrice.compareTo(b.sellPrice);
  static int _purchasePriceAcending(Price a, Price b) =>
      a.purchasePrice.compareTo(b.purchasePrice);

  /// Get the percentile for the purchase price of a trade good.
  int? percentileForPurchasePrice(String symbol, int purchasePrice) =>
      _percentileFor(
        symbol,
        Price._compareOnly(purchasePrice: purchasePrice),
        MarketTransactionTypeEnum.PURCHASE,
      );

  /// Get the median purchase price for a trade good.
  int? medianPurchasePrice(String symbol) =>
      purchasePriceAtPercentile(symbol, 50);

  /// Get the percentile purchase price for a trade good.
  /// [percentile] must be between 0 and 100.
  int? purchasePriceAtPercentile(String symbol, int percentile) {
    final maybePrice = _priceAtPercentile(
      symbol,
      percentile,
      MarketTransactionTypeEnum.PURCHASE,
    );
    return maybePrice?.purchasePrice;
  }

  /// Get the percentile for the sell price of a trade good.
  int? percentileForSellPrice(String symbol, int sellPrice) => _percentileFor(
        symbol,
        Price._compareOnly(sellPrice: sellPrice),
        MarketTransactionTypeEnum.SELL,
      );

  /// Get the median sell price for a trade good.
  int? medianSellPrice(String symbol) => sellPriceAtPercentile(symbol, 50);

  /// Get the percentile sell price for a trade good.
  /// [percentile] must be between 0 and 100.
  int? sellPriceAtPercentile(String symbol, int percentile) {
    final maybePrice = _priceAtPercentile(
      symbol,
      percentile,
      MarketTransactionTypeEnum.SELL,
    );
    return maybePrice?.sellPrice;
  }

  /// Return true if the sell price is in above the [goodPercentile] percentile.
  bool isGoodSellPrice(
    String symbol,
    int sellPrice, {
    int goodPercentile = 50,
  }) {
    final percentile = percentileForSellPrice(symbol, sellPrice);
    if (percentile == null) {
      return false;
    }
    return percentile >= goodPercentile;
  }

  /// Return true if the purchase price is in below the [goodPercentile]
  /// percentile.
  bool isGoodPurchasePrice(
    String symbol,
    int purchasePrice, {
    int goodPercentile = 50,
  }) {
    final percentile = percentileForPurchasePrice(symbol, purchasePrice);
    if (percentile == null) {
      return false;
    }
    return percentile <= goodPercentile;
  }

  /// Returns all known sell prices for a trade good, optionally restricted
  /// to a specific waypoint.
  Iterable<Price> sellPricesFor({
    required String tradeSymbol,
    String? marketSymbol,
  }) {
    final filter = marketSymbol == null
        ? (Price e) => e.symbol == tradeSymbol && e.sellPrice > 0
        : (Price e) =>
            e.symbol == tradeSymbol &&
            e.sellPrice > 0 &&
            e.waypointSymbol == marketSymbol;
    return _prices.where(filter);
  }

  /// Returns all known purchase prices for a trade good, optionally restricted
  /// to a specific waypoint.
  Iterable<Price> purchasePricesFor({
    required String tradeSymbol,
    String? marketSymbol,
  }) {
    final filter = marketSymbol == null
        ? (Price e) => e.symbol == tradeSymbol && e.purchasePrice > 0
        : (Price e) =>
            e.symbol == tradeSymbol &&
            e.purchasePrice > 0 &&
            e.waypointSymbol == marketSymbol;
    return _prices.where(filter);
  }

  Price? _priceAtPercentile(
    String symbol,
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
    final pricesForSymbol = action == MarketTransactionTypeEnum.PURCHASE
        ? purchasePricesFor(tradeSymbol: symbol)
        : sellPricesFor(tradeSymbol: symbol);
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

  int? _percentileFor(
    String symbol,
    Price price,
    MarketTransactionTypeEnum action,
  ) {
    final compareTo = action == MarketTransactionTypeEnum.PURCHASE
        ? _purchasePriceAcending
        : _sellPriceAcending;
    final pricesForSymbol = action == MarketTransactionTypeEnum.PURCHASE
        ? purchasePricesFor(tradeSymbol: symbol)
        : sellPricesFor(tradeSymbol: symbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    // for (final price in pricesForSymbolSorted) {
    //   logger.info(
    //     '{${price.waypointSymbol}} ${price.sellPrice}',
    //   );
    // }

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

  /// Returns true if there is recent market data for a given market.
  /// Does not check if the passed in market is a valid market.
  bool hasRecentMarketData(
    String marketSymbol, {
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForMarket =
        _prices.where((e) => e.waypointSymbol == marketSymbol);
    if (pricesForMarket.isEmpty) {
      return false;
    }
    final pricesForMarketSorted = pricesForMarket.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return pricesForMarketSorted.last.timestamp.difference(DateTime.now()) <
        maxAge;
  }

  /// Most recent price a good can be sold to the market for.
  /// [marketSymbol] is the symbol for the market.
  /// [tradeSymbol] is the symbol for the trade good.
  /// [maxAge] is the maximum age of the price in the cache.
  int? recentSellPrice({
    required String marketSymbol,
    required String tradeSymbol,
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForSymbol =
        sellPricesFor(tradeSymbol: tradeSymbol, marketSymbol: marketSymbol);
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
  int? recentPurchasePrice({
    required String marketSymbol,
    required String tradeSymbol,
    Duration maxAge = defaultMaxAge,
  }) {
    final pricesForSymbol = purchasePricesFor(
      tradeSymbol: tradeSymbol,
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
Future<void> recordMarketDataAndLog(
  PriceData priceData,
  Market market,
  Ship ship,
) async {
  await recordMarketData(priceData, market);
  shipInfo(ship, 'Recorded Market data for ${market.symbol}');
}

/// Record market data.
Future<void> recordMarketData(PriceData priceData, Market market) async {
  final prices = market.tradeGoods
      .map((g) => Price.fromMarketTradeGood(g, market.symbol))
      .toList();
  await priceData.addPrices(prices);
}
