import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

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

  Price._compareOnly({this.purchasePrice = 0, this.sellPrice = 0})
      : waypointSymbol = '',
        symbol = '',
        supply = MarketTradeGoodSupplyEnum.ABUNDANT,
        tradeVolume = 0,
        timestamp = DateTime.now();

  /// Create a new price record from a json map.
  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      waypointSymbol: json['waypointSymbol'] as String,
      symbol: json['symbol'] as String,
      supply: MarketTradeGoodSupplyEnum.fromJson(json['supply'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      tradeVolume: json['tradeVolume'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// The waypoint of the market where this price was recorded.
  final String waypointSymbol;

  /// The symbol of the trade good.
  final String symbol;

  /// The supply level of the trade good.
  final MarketTradeGoodSupplyEnum supply;

  /// The purchase price of the trade good.
  final int purchasePrice;

  /// The sell price of the trade good.
  final int sellPrice;

  /// The trade volume of the trade good.
  final int tradeVolume;

  /// The timestamp of the price record.
  final DateTime timestamp;
}

/// A collection of price records.
class PriceData {
  /// Create a new price data collection.
  PriceData(this.prices, this.cacheFilePath);

  // Eventually we should keep our own data and not use the global data.
  /// Url from which to fetch the global price data.
  static const String defaultUrl = 'https://st.feba66.de/prices';

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'prices.json';

  /// The path to the cache file.
  final String cacheFilePath;

  /// The list of price records.
  final List<Price> prices;

  static List<Price> _parsePrices(String prices) {
    final parsed = jsonDecode(prices) as List<dynamic>;
    return parsed
        .map<Price>((e) => Price.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static PriceData? _loadPricesCache(String cacheFilePath) {
    final pricesFile = File(cacheFilePath);
    if (pricesFile.existsSync()) {
      return PriceData(
        _parsePrices(pricesFile.readAsStringSync()),
        cacheFilePath,
      );
    }
    return null;
  }

  static void _savePricesCache({
    required String jsonString,
    required String cacheFilePath,
  }) {
    File(cacheFilePath).writeAsStringSync(jsonString);
  }

  /// Load the price data from the cache or from the url.
  static Future<PriceData> load({String? cacheFilePath, String? url}) async {
    final uri = Uri.parse(url ?? defaultUrl);
    final filePath = cacheFilePath ?? defaultCacheFilePath;
    // Try to load prices.json.  If it does not exist, pull down and cache
    // from the url.
    final fromCache = _loadPricesCache(filePath);
    if (fromCache != null) {
      return fromCache;
    }
    logger.info("Couldn't load prices from cache, fetching from $uri");
    final response = await http.get(uri);
    final data = PriceData(_parsePrices(response.body), filePath);
    _savePricesCache(jsonString: response.body, cacheFilePath: filePath);
    return data;
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
        _purchasePriceAcending,
      );

  /// Get the median purchase price for a trade good.
  int? medianPurchasePrice(String symbol) {
    final maybePrice = _medianPriceFor(
      symbol,
      _purchasePriceAcending,
    );
    return maybePrice?.purchasePrice;
  }

  /// Get the percentile for the sell price of a trade good.
  int? percentileForSellPrice(String symbol, int sellPrice) => _percentileFor(
        symbol,
        Price._compareOnly(sellPrice: sellPrice),
        _sellPriceAcending,
      );

  /// Get the median sell price for a trade good.
  int? medianSellPrice(String symbol) {
    final maybePrice = _medianPriceFor(
      symbol,
      _sellPriceAcending,
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

  Price? _medianPriceFor(
    String symbol,
    int Function(Price a, Price b) compareTo,
  ) {
    final pricesForSymbol = prices.where((e) => e.symbol == symbol);
    if (pricesForSymbol.isEmpty) {
      return null;
    }
    // Sort the prices in ascending order.
    final pricesForSymbolSorted = pricesForSymbol.toList()..sort(compareTo);
    return pricesForSymbolSorted[pricesForSymbolSorted.length ~/ 2];
  }

  int? _percentileFor(
    String symbol,
    Price price,
    int Function(Price a, Price b) compareTo,
  ) {
    final pricesForSymbol = prices.where((e) => e.symbol == symbol);
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
}
