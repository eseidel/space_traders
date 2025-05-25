import 'package:openapi/model/trade_symbol.dart';

class SellCargoRequest {
  SellCargoRequest({required this.symbol, required this.units});

  factory SellCargoRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SellCargoRequest(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SellCargoRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SellCargoRequest.fromJson(json);
  }

  TradeSymbol symbol;
  int units;

  Map<String, dynamic> toJson() {
    return {'symbol': symbol.toJson(), 'units': units};
  }
}
