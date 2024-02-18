import 'package:meta/meta.dart';
import 'package:types/api.dart';
import 'package:types/src/symbol.dart';

/// A class to hold transaction data from construction delivery.
@immutable
class ConstructionDelivery {
  /// Deliver goods for construction.
  const ConstructionDelivery({
    required this.unitsDelivered,
    required this.tradeSymbol,
    required this.shipSymbol,
    required this.timestamp,
    required this.waypointSymbol,
  });

  /// The number of units delivered.
  final int unitsDelivered;

  /// The TradeSymbol of the units delivered.
  final TradeSymbol tradeSymbol;

  /// The ShipSymbol of the ship that performed the action.
  final ShipSymbol shipSymbol;

  /// The timestamp of the action.
  final DateTime timestamp;

  /// The location of the action.
  final WaypointSymbol waypointSymbol;
}

// Can't be immutable because Construction is not immutable.
/// A cached construction value or null known to be not under construction.
class ConstructionRecord {
  /// Creates a new construction record.
  const ConstructionRecord({
    required this.waypointSymbol,
    required this.construction,
    required this.timestamp,
  });

  /// Creates a new construction record from JSON.
  factory ConstructionRecord.fromJson(Map<String, dynamic> json) {
    return ConstructionRecord(
      construction: Construction.fromJson(json['construction']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
    );
  }

  /// The waypoint symbol.
  final WaypointSymbol waypointSymbol;

  /// The last time this record was updated.
  final DateTime timestamp;

  /// The construction value if under construction.
  final Construction? construction;

  /// Whether the waypoint is under construction.
  bool get isUnderConstruction =>
      construction != null && !construction!.isComplete;

  /// Converts this object to a JSON encodable object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'construction': construction?.toJson(),
        'waypointSymbol': waypointSymbol.toJson(),
      };
}
