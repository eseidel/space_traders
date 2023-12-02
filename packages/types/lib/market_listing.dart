import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// Object which caches all the static data for a market.
@immutable
class MarketListing {
  /// Creates a new market listing.
  const MarketListing({
    required this.waypointSymbol,
    this.exports = const {},
    this.imports = const {},
    this.exchange = const {},
  });

  /// Creates a new market description from JSON data.
  factory MarketListing.fromJson(Map<String, dynamic> json) {
    final symbol = WaypointSymbol.fromJson(json['waypointSymbol'] as String);
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
      waypointSymbol: symbol,
      exports: exports.toSet(),
      imports: imports.toSet(),
      exchange: exchange.toSet(),
    );
  }

  /// The symbol of the market. The symbol is the same as the waypoint where the
  /// market is located.
  final WaypointSymbol waypointSymbol;

  /// The list of goods that are exported from this market.
  final Set<TradeSymbol> exports;

  /// The list of goods that are sought as imports in this market.
  final Set<TradeSymbol> imports;

  /// The list of goods that are bought and sold between agents at this market.
  final Set<TradeSymbol> exchange;

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
      'waypointSymbol': waypointSymbol.toJson(),
      'exports': exports.map((e) => e.toJson()).toList()..sort(),
      'imports': imports.map((e) => e.toJson()).toList()..sort(),
      'exchange': exchange.map((e) => e.toJson()).toList()..sort(),
    };
  }

  @override
  bool operator ==(Object other) {
    const equality = SetEquality<TradeSymbol>();
    return identical(this, other) ||
        other is MarketListing &&
            runtimeType == other.runtimeType &&
            waypointSymbol == other.waypointSymbol &&
            equality.equals(exports, other.exports) &&
            equality.equals(imports, other.imports) &&
            equality.equals(exchange, other.exchange);
  }

  @override
  int get hashCode => Object.hashAll([
        waypointSymbol,
        exports,
        imports,
        exchange,
      ]);
}
