import 'package:meta/meta.dart';
import 'package:spacetraders/model/trade_symbol.dart';

@immutable
class ShipRefine201ResponseDataPropConsumedPropInner {
  const ShipRefine201ResponseDataPropConsumedPropInner({
    required this.tradeSymbol,
    required this.units,
  });

  factory ShipRefine201ResponseDataPropConsumedPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return ShipRefine201ResponseDataPropConsumedPropInner(
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefine201ResponseDataPropConsumedPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipRefine201ResponseDataPropConsumedPropInner.fromJson(json);
  }

  final TradeSymbol tradeSymbol;
  final int units;

  Map<String, dynamic> toJson() {
    return {'tradeSymbol': tradeSymbol.toJson(), 'units': units};
  }

  @override
  int get hashCode => Object.hashAll([tradeSymbol, units]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipRefine201ResponseDataPropConsumedPropInner &&
        tradeSymbol == other.tradeSymbol &&
        units == other.units;
  }
}
