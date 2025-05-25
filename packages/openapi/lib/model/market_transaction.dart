import 'package:openapi/model/market_transaction_type.dart';

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

  factory MarketTransaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
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

  String waypointSymbol;
  String shipSymbol;
  String tradeSymbol;
  MarketTransactionType type;
  int units;
  int pricePerUnit;
  int totalPrice;
  DateTime timestamp;

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
}
