import 'package:cli/cli.dart';
import 'package:cli/config.dart';

/// A snapshot of the charting records.
class ChartingSnapshot {
  /// Creates a new charting snapshot.
  ChartingSnapshot(Iterable<ChartingRecord> records) {
    for (final record in records) {
      _recordsByWaypointSymbol[record.waypointSymbol] = record;
    }
  }

  /// Creates a new charting snapshot from the database.
  static Future<ChartingSnapshot> load(Database db) async {
    final records = await db.allChartingRecords();
    return ChartingSnapshot(records.toList());
  }

  /// The charting records.
  final Map<WaypointSymbol, ChartingRecord> _recordsByWaypointSymbol =
      <WaypointSymbol, ChartingRecord>{};

  /// The charting records.
  Iterable<ChartingRecord> get records => _recordsByWaypointSymbol.values;

  /// The number of waypoints in this snapshot.
  /// Records are expected to be one-per-waypoint but this method is
  /// separate from [records] on the assumption that may change.
  int get waypointCount => _recordsByWaypointSymbol.length;

  /// Returns all charted values.
  Iterable<ChartedValues> get values =>
      records.where((r) => r.values != null).map((r) => r.values!);

  /// Returns true if the given waypoint is known to be charted.
  /// Will return null if the waypoint is not in the snapshot.
  bool? isCharted(WaypointSymbol waypointSymbol) =>
      getRecord(waypointSymbol)?.isCharted;

  /// Returns the ChartingRecord for the given waypoint, or null if it is not
  /// in the snapshot.
  ChartingRecord? getRecord(WaypointSymbol waypointSymbol) =>
      _recordsByWaypointSymbol[waypointSymbol];

  /// Returns the ChartingRecord for the given waypoint, or null if it is not
  ChartingRecord? operator [](WaypointSymbol waypointSymbol) =>
      getRecord(waypointSymbol);
}

/// A cache of charted values from Waypoints.
class ChartingCache {
  /// Creates a new connection to the charting cache.
  ChartingCache(Database db) : _db = db;

  final Database _db;

  /// Returns true if the given waypoint is known to be charted.
  Future<bool?> isCharted(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async =>
      (await chartingRecord(waypointSymbol, maxAge: maxAge))?.isCharted;

  /// Returns the charted values for the given waypoint, or null if it is not
  /// in the cache.
  Future<ChartedValues?> chartedValues(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async =>
      (await chartingRecord(waypointSymbol, maxAge: maxAge))?.values;

  /// Returns the charting record for the given waypoint, or null if it is not
  /// in the cache.
  Future<ChartingRecord?> chartingRecord(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async =>
      await _db.getChartingRecord(waypointSymbol, maxAge);

  /// Creates a ChartingSnapshot from the database.
  Future<ChartingSnapshot> snapshot() async =>
      ChartingSnapshot((await _db.allChartingRecords()).toList());

  /// Adds a waypoint to the cache.
  ///     waypointTraits.addAll(waypoint.traits);
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
    await _db.upsertChartingRecord(chartingRecord);
  }

  /// Adds a list of waypoints to the cache.
  Future<void> addWaypoints(Iterable<Waypoint> waypoints) async {
    for (final waypoint in waypoints) {
      await addWaypoint(waypoint);
    }
  }
}
