import 'package:openapi/model/trade_symbol.dart';

class ShipRefine201ResponseDataProducedInner {
  ShipRefine201ResponseDataProducedInner({
    required this.tradeSymbol,
    required this.units,
  });

  factory ShipRefine201ResponseDataProducedInner.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipRefine201ResponseDataProducedInner(
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefine201ResponseDataProducedInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipRefine201ResponseDataProducedInner.fromJson(json);
  }

  TradeSymbol tradeSymbol;
  int units;

  Map<String, dynamic> toJson() {
    return {'tradeSymbol': tradeSymbol.toJson(), 'units': units};
  }
}
