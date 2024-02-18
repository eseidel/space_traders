import 'package:collection/collection.dart';
import 'package:db/src/query.dart';
import 'package:meta/meta.dart';
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

/// A charted value.
@immutable
class ChartedValues {
  /// Creates a new charted values.
  const ChartedValues({
    required this.chart,
    required this.faction,
    required this.traitSymbols,
  });

  /// Creates a new charted values for testing.
  @visibleForTesting
  factory ChartedValues.test({
    WaypointFaction? faction,
    Set<WaypointTraitSymbol>? traitSymbols,
    Chart? chart,
  }) =>
      ChartedValues(
        faction: faction,
        traitSymbols: traitSymbols ?? {},
        chart: chart ?? Chart(),
      );

  /// Creates a new charted values from JSON data.
  factory ChartedValues.fromJson(Map<String, dynamic> json) {
    final faction =
        WaypointFaction.fromJson(json['faction'] as Map<String, dynamic>?);
    final traitSymbols = (json['traitSymbols'] as List<dynamic>)
        .cast<String>()
        .map((e) => WaypointTraitSymbol.fromJson(e)!)
        .toSet();
    final chart = Chart.fromJson(json['chart'] as Map<String, dynamic>)!;
    return ChartedValues(
      faction: faction,
      traitSymbols: traitSymbols,
      chart: chart,
    );
  }

  /// Creates a new charted values from JSON data.
  static ChartedValues? fromJsonOrNull(Map<String, dynamic>? json) =>
      json == null ? null : ChartedValues.fromJson(json);

  /// Faction for this waypoint.
  final WaypointFaction? faction;

  /// The traits of the waypoint.
  final Set<WaypointTraitSymbol> traitSymbols;

  /// Chart for this waypoint.
  final Chart chart;

  /// Converts this charted values to JSON data.
  Map<String, dynamic> toJson() {
    final sortedTradeSymbols = traitSymbols.sortedBy((s) => s.value);
    return <String, dynamic>{
      'faction': faction?.toJson(),
      'traitSymbols': sortedTradeSymbols,
      'chart': chart.toJson(),
    };
  }

  /// Whether this waypoint has a shipyard.
  bool get hasShipyard => traitSymbols.contains(WaypointTraitSymbol.SHIPYARD);

  /// Whether this waypoint has a market.
  bool get hasMarket => traitSymbols.contains(WaypointTraitSymbol.MARKETPLACE);
}

/// Charting record for a given waypoint.
class ChartingRecord {
  /// Creates a new charting record.
  const ChartingRecord({
    required this.waypointSymbol,
    required this.values,
    required this.timestamp,
  });

  /// Creates a new charting record from JSON data.
  ChartingRecord.fromJson(Map<String, dynamic> json)
      : values = ChartedValues.fromJsonOrNull(
          json['values'] as Map<String, dynamic>?,
        ),
        waypointSymbol =
            WaypointSymbol.fromJson(json['waypointSymbol'] as String),
        timestamp = DateTime.parse(json['timestamp'] as String);

  /// Symbol for this waypoint.
  final WaypointSymbol waypointSymbol;

  /// The charted values.  Will be null for uncharted waypoints.
  final ChartedValues? values;

  /// The timestamp for this record.
  final DateTime timestamp;

  /// Whether this waypoint was charted at record time.
  bool get isCharted => values != null;

  /// Converts this charting record to JSON data.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'values': values?.toJson(),
        'waypointSymbol': waypointSymbol.toJson(),
        'timestamp': timestamp.toIso8601String(),
      };
}
