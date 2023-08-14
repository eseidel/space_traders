import 'package:db/query.dart';
import 'package:types/types.dart';

/// Query to insert an extraction.
Query insertExtractionQuery(ExtractionRecord extraction) {
  return Query(
    'INSERT INTO extractions (ship_symbol, waypoint_symbol, trade_symbol, '
    'quantity, power, survey_signature, timestamp) VALUES (@shipSymbol, '
    '@waypointSymbol, @tradeSymbol, @quantity, @power, @surveySignature, '
    '@timestamp)',
    substitutionValues: extractionToColumnMap(extraction),
  );
}

/// Convert an extraction to a column map.
Map<String, dynamic> extractionToColumnMap(ExtractionRecord extraction) {
  return {
    'shipSymbol': extraction.shipSymbol.toJson(),
    'waypointSymbol': extraction.waypointSymbol.toJson(),
    'tradeSymbol': extraction.tradeSymbol.toJson(),
    'quantity': extraction.quantity,
    'power': extraction.power,
    'surveySignature': extraction.surveySignature,
    'timestamp': extraction.timestamp,
  };
}

/// Convert a row result into an extraction.
ExtractionRecord extractionFromRowResult(Map<String, dynamic> values) {
  return ExtractionRecord(
    shipSymbol: ShipSymbol.fromString(values['ship_symbol'] as String),
    waypointSymbol:
        WaypointSymbol.fromString(values['waypoint_symbol'] as String),
    tradeSymbol: TradeSymbol.fromJson(values['trade_symbol'] as String)!,
    quantity: values['quantity'] as int,
    power: values['power'] as int,
    surveySignature: values['survey_signature'] as String?,
    timestamp: values['timestamp'] as DateTime,
  );
}
