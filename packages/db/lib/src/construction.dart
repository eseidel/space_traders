import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Convert a row result into a ConstructionRecord.
ConstructionRecord constructionFromColumnMap(Map<String, dynamic> values) {
  // ignoring is_complete from the db, computing from construction instead.
  return ConstructionRecord(
    construction: Construction.fromJson(values['construction']),
    timestamp: values['timestamp'] as DateTime,
    waypointSymbol:
        WaypointSymbol.fromJson(values['waypoint_symbol'] as String),
  );
}

/// Convert a ConstructionRecord into substitution values for a query.
Map<String, dynamic> constructionToColumnMap(ConstructionRecord survey) {
  return {
    'waypoint_symbol': survey.waypointSymbol.toJson(),
    'construction': survey.construction?.toJson(),
    'timestamp': survey.timestamp,
    'is_complete': !survey.isUnderConstruction,
  };
}

/// Insert or Update a ConstructionRecord into the database.
Query upsertConstructionQuery(ConstructionRecord record) {
  // Insert the ConstructionRecord or update it if it already exists.
  return Query(
    'INSERT INTO construction_ (waypoint_symbol, construction, timestamp, '
    'is_complete) '
    'VALUES (@waypoint_symbol, @construction, @timestamp, @is_complete) '
    'ON CONFLICT (waypoint_symbol) DO UPDATE SET '
    'construction = @construction, '
    'timestamp = @timestamp, '
    'is_complete = @is_complete ',
    parameters: constructionToColumnMap(record),
  );
}

/// Get a ConstructionRecord from the database.
Query getConstructionQuery(WaypointSymbol waypointSymbol, Duration maxAge) {
  return Query(
    'SELECT * FROM construction_ '
    'WHERE waypoint_symbol = @waypoint_symbol '
    'AND timestamp > @timestamp',
    parameters: {
      'waypoint_symbol': waypointSymbol.toJson(),
      'timestamp': DateTime.timestamp().subtract(maxAge),
    },
  );
}

/// Select all ConstructionRecords from the database.
Query allConstructionQuery() {
  return const Query('SELECT * FROM construction_');
}
