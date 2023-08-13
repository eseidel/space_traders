import 'package:cli/cache/json_log.dart';
import 'package:file/file.dart';
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
}

/// A class to manage a extraction log file.
class ExtractionLog extends JsonLog<ExtractionRecord> {
  /// Create a new extraction log.
  ExtractionLog(
    super.entries, {
    required super.fs,
    required super.path,
  }) : super(recordToJson: (record) => record.toJson());

  /// The default path to the extraction log.
  static const String defaultPath = 'data/extractions.json';

  /// Load the extraction log from the file system.
  // ignore: prefer_constructors_over_static_methods
  static ExtractionLog load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final entries =
        JsonLog.load<ExtractionRecord>(fs, path, ExtractionRecord.fromJson);
    return ExtractionLog(entries, fs: fs, path: path);
  }

  /// Return extractions with the given filter applied.
  List<ExtractionRecord> where(bool Function(ExtractionRecord t) filter) {
    return entries.where(filter).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }
}
