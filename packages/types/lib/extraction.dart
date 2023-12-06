import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A class to hold extraction data from a ship.
@immutable
class ExtractionRecord extends Equatable {
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

  @override
  List<Object?> get props => [
        shipSymbol,
        waypointSymbol,
        tradeSymbol,
        quantity,
        power,
        surveySignature,
        timestamp,
      ];

  /// Return a JSON map for this extraction.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'shipSymbol': shipSymbol.toJson(),
      'waypointSymbol': waypointSymbol.toJson(),
      'tradeSymbol': tradeSymbol.toJson(),
      'quantity': quantity,
      'power': power,
      'surveySignature': surveySignature,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
