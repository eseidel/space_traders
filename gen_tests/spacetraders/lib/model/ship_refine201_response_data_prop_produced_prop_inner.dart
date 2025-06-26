import 'package:meta/meta.dart';
import 'package:spacetraders/model/trade_symbol.dart';

@immutable
class ShipRefine201ResponseDataPropProducedPropInner {
  const ShipRefine201ResponseDataPropProducedPropInner({
    required this.tradeSymbol,
    required this.units,
  });

  factory ShipRefine201ResponseDataPropProducedPropInner.fromJson(
    Map<String, dynamic> json,
  ) {
    return ShipRefine201ResponseDataPropProducedPropInner(
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipRefine201ResponseDataPropProducedPropInner? maybeFromJson(
    Map<String, dynamic>? json,
  ) {
    if (json == null) {
      return null;
    }
    return ShipRefine201ResponseDataPropProducedPropInner.fromJson(json);
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
    return other is ShipRefine201ResponseDataPropProducedPropInner &&
        tradeSymbol == other.tradeSymbol &&
        units == other.units;
  }
}
