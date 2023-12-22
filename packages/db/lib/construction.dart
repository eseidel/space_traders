import 'package:db/query.dart';
import 'package:types/types.dart';

/// Convert a row result into a ConstructionRecord.
ConstructionRecord constructionFromColumnMap(Map<String, dynamic> values) {
  // ignoring is_complete from the db, computing from construction instead.
  return ConstructionRecord(
    construction: Construction.fromJson(values['construction']),
    timestamp: DateTime.parse(values['timestamp'] as String),
    waypointSymbol: WaypointSymbol.fromJson(values['waypointSymbol'] as String),
  );
}

/// Convert a ConstructionRecord into substitution values for a query.
Map<String, dynamic> constructionToColumnMap(ConstructionRecord survey) {
  return {
    'waypointSymbol': survey.waypointSymbol.toJson(),
    'construction': survey.construction?.toJson(),
    'timestamp': survey.timestamp,
    'is_complete': !survey.isUnderConstruction,
  };
}

/// Insert a ConstructionRecord into the database.
Query insertConstructionQuery(ConstructionRecord record) {
  // Insert the ConstructionRecord or update it if it already exists.
  return Query(
    'INSERT INTO construction_ (waypoint_symbol, construction, timestamp, is_complete, json) '
    'VALUES (@waypointSymbol, @construction, @timestamp, @is_complete, @json) '
    'ON CONFLICT (waypoint_symbol) DO UPDATE SET '
    'construction = @construction, '
    'timestamp = @timestamp, '
    'is_complete = @is_complete, '
    'json = @json',
    substitutionValues: constructionToColumnMap(record),
  );
}
