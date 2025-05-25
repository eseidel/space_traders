import 'package:openapi/model/trade_symbol.dart';

class ShipRefine201ResponseDataConsumedInner {
  ShipRefine201ResponseDataConsumedInner({
    required this.tradeSymbol,
    required this.units,
  });

  factory ShipRefine201ResponseDataConsumedInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipRefine201ResponseDataConsumedInner(
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefine201ResponseDataConsumedInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipRefine201ResponseDataConsumedInner.fromJson(json);
  }

  TradeSymbol tradeSymbol;
  int units;

  Map<String, dynamic> toJson() {
    return {'tradeSymbol': tradeSymbol.toJson(), 'units': units};
  }
}
