import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Convert a row result into a ChartingRecord.
ChartingRecord chartingRecordFromColumnMap(Map<String, dynamic> values) {
  return ChartingRecord(
    waypointSymbol:
        WaypointSymbol.fromJson(values['waypoint_symbol'] as String),
    values:
        ChartedValues.fromJsonOrNull(values['values'] as Map<String, dynamic>?),
    timestamp: values['timestamp'] as DateTime,
  );
}

/// Convert a ChartingRecord into substitution values for a query.
Map<String, dynamic> chartingRecordToColumnMap(ChartingRecord record) {
  return {
    'waypoint_symbol': record.waypointSymbol.toJson(),
    'values': record.values?.toJson(),
    'timestamp': record.timestamp,
  };
}

/// Insert or Update a ChartingRecord into the database.
Query upsertChartingRecordQuery(ChartingRecord record) {
  // Insert the ChartingRecord or update it if it already exists.
  return Query(
    'INSERT INTO charting_ (waypoint_symbol, values, timestamp) '
    'VALUES (@waypoint_symbol, @values, @timestamp) '
    'ON CONFLICT (waypoint_symbol) DO UPDATE SET '
    'values = @values, '
    'timestamp = @timestamp ',
    parameters: chartingRecordToColumnMap(record),
  );
}

/// Get a ChartingRecord from the database.
Query getChartingRecordQuery(WaypointSymbol waypointSymbol, Duration maxAge) {
  // Get all records which *either* are charted *or* are uncharted but
  // younger than maxAge.  Once something is charted it never changes.
  return Query(
    'SELECT * FROM charting_ '
    'WHERE waypoint_symbol = @waypoint_symbol '
    'AND (values IS NOT NULL OR timestamp > @max_age) ',
    parameters: {
      'waypoint_symbol': waypointSymbol.toJson(),
      'max_age': DateTime.timestamp().subtract(maxAge),
    },
  );
}

/// Select all ChartingRecords from the database.
Query allChartingRecordsQuery() {
  return const Query('SELECT * FROM charting_');
}
