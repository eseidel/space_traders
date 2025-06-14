import 'package:openapi/model/trade_symbol.dart';

class SupplyConstructionRequest {
  SupplyConstructionRequest({
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.units,
  });

  factory SupplyConstructionRequest.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return SupplyConstructionRequest(
      shipSymbol: json['shipSymbol'] as String,
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String),
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static SupplyConstructionRequest? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return SupplyConstructionRequest.fromJson(json);
  }

  String shipSymbol;
  TradeSymbol tradeSymbol;
  int units;

  Map<String, dynamic> toJson() {
    return {
      'shipSymbol': shipSymbol,
      'tradeSymbol': tradeSymbol.toJson(),
      'units': units,
    };
  }

  @override
  int get hashCode => Object.hash(shipSymbol, tradeSymbol, units);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplyConstructionRequest &&
        shipSymbol == other.shipSymbol &&
        tradeSymbol == other.tradeSymbol &&
        units == other.units;
  }
}
