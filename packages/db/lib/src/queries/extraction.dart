import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query to get all extractions.
Query allExtractionsQuery() {
  return const Query(
    'SELECT ship_symbol, waypoint_symbol, trade_symbol, quantity, power, '
    'survey_signature, timestamp FROM extraction_',
  );
}

/// Query to insert an extraction.
Query insertExtractionQuery(ExtractionRecord extraction) {
  return Query(
    'INSERT INTO extraction_ (ship_symbol, waypoint_symbol, trade_symbol, '
    'quantity, power, survey_signature, timestamp) VALUES (@ship_symbol, '
    '@waypoint_symbol, @trade_symbol, @quantity, @power, @survey_signature, '
    '@timestamp)',
    parameters: extractionToColumnMap(extraction),
  );
}

/// Convert an extraction to a column map.
Map<String, dynamic> extractionToColumnMap(ExtractionRecord extraction) {
  return {
    'ship_symbol': extraction.shipSymbol.toJson(),
    'waypoint_symbol': extraction.waypointSymbol.toJson(),
    'trade_symbol': extraction.tradeSymbol.toJson(),
    'quantity': extraction.quantity,
    'power': extraction.power,
    'survey_signature': extraction.surveySignature,
    'timestamp': extraction.timestamp,
  };
}

/// Convert a row result into an extraction.
ExtractionRecord extractionFromColumnMap(Map<String, dynamic> values) {
  return ExtractionRecord(
    shipSymbol: ShipSymbol.fromString(values['ship_symbol'] as String),
    waypointSymbol: WaypointSymbol.fromString(
      values['waypoint_symbol'] as String,
    ),
    tradeSymbol: TradeSymbol.fromJson(values['trade_symbol'] as String),
    quantity: values['quantity'] as int,
    power: values['power'] as int,
    surveySignature: values['survey_signature'] as String?,
    timestamp: values['timestamp'] as DateTime,
  );
}
