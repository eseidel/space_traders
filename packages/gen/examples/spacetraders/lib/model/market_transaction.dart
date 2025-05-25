import 'package:spacetraders/model/market_transaction_type.dart';

class MarketTransaction {
  MarketTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.tradeSymbol,
    required this.type,
    required this.units,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.timestamp,
  });

  factory MarketTransaction.fromJson(Map<String, dynamic> json) {
    return MarketTransaction(
      waypointSymbol: json['waypointSymbol'] as String,
      shipSymbol: json['shipSymbol'] as String,
      tradeSymbol: json['tradeSymbol'] as String,
      type: MarketTransactionType.fromJson(json['type'] as String),
      units: json['units'] as int,
      pricePerUnit: json['pricePerUnit'] as int,
      totalPrice: json['totalPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static MarketTransaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return MarketTransaction.fromJson(json);
  }

  final String waypointSymbol;
  final String shipSymbol;
  final String tradeSymbol;
  final MarketTransactionType type;
  final int units;
  final int pricePerUnit;
  final int totalPrice;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol,
      'shipSymbol': shipSymbol,
      'tradeSymbol': tradeSymbol,
      'type': type.toJson(),
      'units': units,
      'pricePerUnit': pricePerUnit,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  int get hashCode => Object.hash(
    waypointSymbol,
    shipSymbol,
    tradeSymbol,
    type,
    units,
    pricePerUnit,
    totalPrice,
    timestamp,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MarketTransaction &&
        waypointSymbol == other.waypointSymbol &&
        shipSymbol == other.shipSymbol &&
        tradeSymbol == other.tradeSymbol &&
        type == other.type &&
        units == other.units &&
        pricePerUnit == other.pricePerUnit &&
        totalPrice == other.totalPrice &&
        timestamp == other.timestamp;
  }
}
