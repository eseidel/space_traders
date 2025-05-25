import 'package:openapi/model/trade_symbol.dart';

class ShipCargoItem {
  ShipCargoItem({
    required this.symbol,
    required this.name,
    required this.description,
    required this.units,
  });

  factory ShipCargoItem.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ShipCargoItem(
      symbol: TradeSymbol.fromJson(json['symbol'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      units: json['units'] as int,
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ShipCargoItem? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ShipCargoItem.fromJson(json);
  }

  TradeSymbol symbol;
  String name;
  String description;
  int units;

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol.toJson(),
      'name': name,
      'description': description,
      'units': units,
    };
  }

  @override
  int get hashCode => Object.hash(symbol, name, description, units);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShipCargoItem &&
        symbol == other.symbol &&
        name == other.name &&
        description == other.description &&
        units == other.units;
  }
}
