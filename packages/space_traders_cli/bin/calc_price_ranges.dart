import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
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
class Price {
  Price({
    required this.waypointSymbol,
    required this.symbol,
    required this.supply,
    required this.purchasePrice,
    required this.sellPrice,
    required this.tradeVolume,
    required this.timestamp,
  });

  factory Price.fromJson(Map<String, dynamic> json) {
    return Price(
      waypointSymbol: json['waypointSymbol'] as String,
      symbol: json['symbol'] as String,
      supply: json['supply'] as String,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      tradeVolume: json['tradeVolume'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
  final String waypointSymbol;
  final String symbol;
  final String supply;
  final int purchasePrice;
  final int sellPrice;
  final int tradeVolume;
  final DateTime timestamp;
}

void main(List<String> args) async {
  final uri = Uri.parse('https://st.feba66.de/prices');

  // Try to load prices.json.  If it does not exist, pull down and cache
  // from the url.
  var prices = _loadPricesCache();
  if (prices == null) {
    logger.info("Couldn't load prices from cache, fetching from $uri");
    final response = await http.get(uri);
    prices = _parsePrices(response.body);
    _savePricesCache(response.body);
  }

  logger.info('${prices.length} prices loaded.');
}
