import 'package:db/db.dart';
import 'package:db/src/queries/chart.dart';
import 'package:types/config.dart';
import 'package:types/types.dart';

/// A cache of charted values from Waypoints.
class ChartingStore {
  /// Creates a new connection to the charting cache.
  ChartingStore(Database db) : _db = db;

  final Database _db;

  /// Allow WaypointCache to use this database.
  Database get db => _db;

  /// Return all charting records.
  Future<Iterable<ChartingRecord>> allRecords() async =>
      _db.queryMany(allChartingRecordsQuery(), chartingRecordFromColumnMap);

  /// Return a snapshot of the charting records.
  Future<ChartingSnapshot> snapshotAllRecords() async {
    final records = await allRecords();
    return ChartingSnapshot(records);
  }

  /// Insert a charting record into the database.
  Future<void> upsertChartingRecord(ChartingRecord record) async =>
      _db.execute(upsertChartingRecordQuery(record));

  /// Get a charting record from the database.
  Future<ChartingRecord?> chartingRecord(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => _db.queryOne(
    getChartingRecordQuery(waypointSymbol, maxAge),
    chartingRecordFromColumnMap,
  );

  /// Returns true if the given waypoint is known to be charted.
  Future<bool?> isCharted(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => (await chartingRecord(waypointSymbol, maxAge: maxAge))?.isCharted;

  /// Returns the charted values for the given waypoint, or null if it is not
  /// in the cache.
  Future<ChartedValues?> chartedValues(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => (await chartingRecord(waypointSymbol, maxAge: maxAge))?.values;

  /// Adds a waypoint to the charting cache.
  Future<void> addWaypoint(
    Waypoint waypoint, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    final chart = waypoint.chart;
    final ChartedValues? chartedValues;
    if (chart == null) {
      chartedValues = null;
    } else {
      chartedValues = ChartedValues(
        faction: waypoint.faction,
        traitSymbols: waypoint.traits.map((e) => e.symbol).toSet(),
        chart: chart,
      );
    }
    final chartingRecord = ChartingRecord(
      waypointSymbol: waypoint.symbol,
      values: chartedValues,
      timestamp: getNow(),
    );
    await upsertChartingRecord(chartingRecord);
  }

  /// Adds a list of waypoints to the cache.
  Future<void> addWaypoints(Iterable<Waypoint> waypoints) async {
    for (final waypoint in waypoints) {
      await addWaypoint(waypoint);
    }
  }
}
