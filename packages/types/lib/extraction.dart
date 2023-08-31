import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A class to hold extraction data from a ship.
@immutable
class ExtractionRecord {
  /// Create a new extraction.
  const ExtractionRecord({
    required this.shipSymbol,
    required this.waypointSymbol,
    required this.tradeSymbol,
    required this.quantity,
    required this.power,
    required this.surveySignature,
    required this.timestamp,
  });

  /// A record filled with dummy data to provide to the mocking system.
  @visibleForTesting
  ExtractionRecord.fallbackValue()
      : this(
          shipSymbol: const ShipSymbol('A', 1),
          waypointSymbol: WaypointSymbol.fromString('A-B-C'),
          tradeSymbol: TradeSymbol.IRON_ORE,
          quantity: 1,
          power: 10,
          surveySignature: null,
          timestamp: DateTime(2021),
        );

  /// Create a new extraction from a JSON map.
  factory ExtractionRecord.fromJson(Map<String, dynamic> json) {
    return ExtractionRecord(
      shipSymbol: ShipSymbol.fromString(json['shipSymbol'] as String),
      waypointSymbol:
          WaypointSymbol.fromString(json['waypointSymbol'] as String),
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
      quantity: json['quantity'] as int,
      power: json['power'] as int,
      surveySignature: json['surveySignature'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Ship symbol which made the extraction.
  final ShipSymbol shipSymbol;

  /// Waypoint symbol where the extraction was made.
  final WaypointSymbol waypointSymbol;

  /// Trade symbol of the extracted goods.
  final TradeSymbol tradeSymbol;

  /// Quantity of units extracted.
  final int quantity;

  /// How much power was used in the extraction.
  final int power;

  /// Timestamp of the extraction.
  final DateTime timestamp;

  /// What survey, if any, was used.
  final String? surveySignature;

  /// Return a JSON map for this extraction.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shipSymbol': shipSymbol.toString(),
      'waypointSymbol': waypointSymbol.toString(),
      'tradeSymbol': tradeSymbol.toString(),
      'quantity': quantity,
      'power': power,
      'surveySignature': surveySignature,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Mostly these exists to make testing easier.
  @override
  bool operator ==(Object other) {
    if (other is ExtractionRecord) {
      return shipSymbol == other.shipSymbol &&
          waypointSymbol == other.waypointSymbol &&
          tradeSymbol == other.tradeSymbol &&
          quantity == other.quantity &&
          power == other.power &&
          surveySignature == other.surveySignature &&
          timestamp == other.timestamp;
    }
    return false;
  }

  @override
  int get hashCode => Object.hash(
        shipSymbol,
        waypointSymbol,
        tradeSymbol,
        quantity,
        power,
        surveySignature,
        timestamp,
      );
}
