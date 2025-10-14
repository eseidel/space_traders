import 'package:openapi/model/trade_symbol.dart';

/// A good that can be traded for other goods or currency.

class TradeGood {
  TradeGood({
    required this.symbol,
    required this.name,
    required this.description,
  });

  factory TradeGood.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return TradeGood(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static TradeGood? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return TradeGood.fromJson(json);
  }

  TradeSymbol symbol;
  String name;
  String description;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
    };
  }

  @override
  int get hashCode => Object.hashAll([symbol, name, description]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TradeGood &&
        symbol == other.symbol &&
        name == other.name &&
        description == other.description;
  }
}
