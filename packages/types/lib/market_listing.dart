import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Object which caches all the static data for a market.
@immutable
class MarketListing {
  /// Creates a new market listing.
  const MarketListing({
    required this.symbol,
    this.exports = const [],
    this.imports = const [],
    this.exchange = const [],
  });

  /// Creates a new market description from JSON data.
  factory MarketListing.fromJson(Map<String, dynamic> json) {
    final symbol = WaypointSymbol.fromJson(json['symbol'] as String);
    final exports = (json['exports'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toList();
    final imports = (json['imports'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toList();
    final exchange = (json['exchange'] as List<dynamic>)
        .cast<String>()
        .map((e) => TradeSymbol.fromJson(e)!)
        .toList();
    return MarketListing(
      symbol: symbol,
      exports: exports,
      imports: imports,
      exchange: exchange,
    );
  }

  /// The symbol of the market. The symbol is the same as the waypoint where the
  /// market is located.
  final WaypointSymbol symbol;

  /// The list of goods that are exported from this market.
  final List<TradeSymbol> exports;

  /// The list of goods that are sought as imports in this market.
  final List<TradeSymbol> imports;

  /// The list of goods that are bought and sold between agents at this market.
  final List<TradeSymbol> exchange;

  /// Returns all TradeSymbols traded by the market.
  Iterable<TradeSymbol> get tradeSymbols {
    return imports.followedBy(exports).followedBy(exchange);
  }

  /// Returns true if the market allows trading of the given trade symbol.
  bool allowsTradeOf(TradeSymbol tradeSymbol) =>
      tradeSymbols.contains(tradeSymbol);

  /// Converts this market description to JSON data.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'symbol': symbol.toJson(),
      'exports': exports.map((e) => e.toJson()).toList(),
      'imports': imports.map((e) => e.toJson()).toList(),
      'exchange': exchange.map((e) => e.toJson()).toList(),
    };
  }
}
