import 'package:openapi/model/waypoint_symbol.dart';

/// Result of a chart transaction.

class ChartTransaction {
  ChartTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  factory ChartTransaction.fromJson(dynamic jsonArg) {
    final json = jsonArg as Map<String, dynamic>;
    return ChartTransaction(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      shipSymbol: json['shipSymbol'] as String,
      totalPrice: json['totalPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ChartTransaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ChartTransaction.fromJson(json);
  }

  WaypointSymbol waypointSymbol;
  String shipSymbol;
  int totalPrice;
  DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'waypointSymbol': waypointSymbol.toJson(),
      'shipSymbol': shipSymbol,
      'totalPrice': totalPrice,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  int get hashCode =>
      Object.hashAll([waypointSymbol, shipSymbol, totalPrice, timestamp]);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartTransaction &&
        waypointSymbol == other.waypointSymbol &&
        shipSymbol == other.shipSymbol &&
        totalPrice == other.totalPrice &&
        timestamp == other.timestamp;
  }
}
