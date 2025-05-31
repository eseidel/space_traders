import 'package:openapi/model/trade_symbol.dart';

class SiphonYield {
  SiphonYield({required this.symbol, required this.units});

  factory SiphonYield.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SiphonYield(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SiphonYield? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SiphonYield.fromJson(json);
  }

  TradeSymbol symbol;
  int units;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol.toJson(), 'units': units};
  }

  @override
  int get hashCode => Object.hash(symbol, units);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SiphonYield &&
        symbol == other.symbol &&
        units == other.units;
  }
}
