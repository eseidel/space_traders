import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';

List<Price> _parsePrices(String prices) {
  final parsed = jsonDecode(prices) as List<dynamic>;
  return parsed
      .map<Price>((e) => Price.fromJson(e as Map<String, dynamic>))
      .toList();
}

List<Price>? _loadPricesCache() {
  final pricesFile = File('prices.json');
  if (pricesFile.existsSync()) {
    return _parsePrices(pricesFile.readAsStringSync());
  }
  return null;
}

void _savePricesCache(String prices) {
  File('prices.json').writeAsStringSync(prices);
}

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
  PriceData(this.prices);

  // Eventually we should keep our own data and not use the global data.
  /// Url from which to fetch the global price data.
  static Uri uri = Uri.parse('https://st.feba66.de/prices');

  /// The list of price records.
  final List<Price> prices;

  /// Load the price data from the cache or from the url.
  static Future<PriceData> load() async {
    // Try to load prices.json.  If it does not exist, pull down and cache
    // from the url.
    var prices = _loadPricesCache();
    if (prices == null) {
      logger.info("Couldn't load prices from cache, fetching from $uri");
      final response = await http.get(uri);
      prices = _parsePrices(response.body);
      _savePricesCache(response.body);
    }
    return PriceData(prices);
  }
}
