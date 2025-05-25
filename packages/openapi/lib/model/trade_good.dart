import 'package:openapi/model/trade_symbol.dart';

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
}
