import 'package:meta/meta.dart';
import 'package:spacetraders/model/waypoint_symbol.dart';

@immutable
class ScrapTransaction {
  const ScrapTransaction({
    required this.waypointSymbol,
    required this.shipSymbol,
    required this.totalPrice,
    required this.timestamp,
  });

  factory ScrapTransaction.fromJson(Map<String, dynamic> json) {
    return ScrapTransaction(
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
      shipSymbol: json['shipSymbol'] as String,
      totalPrice: json['totalPrice'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convenience to create a nullable type from a nullable json object.
  /// Useful when parsing optional fields.
  static ScrapTransaction? maybeFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    return ScrapTransaction.fromJson(json);
  }

  final WaypointSymbol waypointSymbol;
  final String shipSymbol;
  final int totalPrice;
  final DateTime timestamp;

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
    return other is ScrapTransaction &&
        waypointSymbol == other.waypointSymbol &&
        shipSymbol == other.shipSymbol &&
        totalPrice == other.totalPrice &&
        timestamp == other.timestamp;
  }
}
