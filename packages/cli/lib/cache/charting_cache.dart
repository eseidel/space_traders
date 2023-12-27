import 'package:cli/cache/json_store.dart';
import 'package:cli/cli.dart';
import 'package:db/chart.dart';

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
  Future<bool?> isCharted(WaypointSymbol waypointSymbol) async =>
      (await chartingRecord(waypointSymbol))?.isCharted;

  /// Returns the charted values for the given waypoint, or null if it is not
  /// in the cache.
  Future<ChartedValues?> chartedValues(WaypointSymbol waypointSymbol) async =>
      (await chartingRecord(waypointSymbol))?.values;

  /// Returns the charting record for the given waypoint, or null if it is not
  /// in the cache.
  Future<ChartingRecord?> chartingRecord(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    return await _db.getChartingRecord(waypointSymbol, maxAge);
  }

  /// Creates a ChartingSnapshot from the database.
  Future<ChartingSnapshot> snapshot() async {
    final records = await _db.allChartingRecords();
    return ChartingSnapshot(records.toList());
  }

  /// Adds a waypoint to the cache.
  ///     waypointTraits.addAll(waypoint.traits);
  Future<void> addWaypoint(
    Waypoint waypoint, {
    bool shouldSave = true,
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
  void addWaypoints(Iterable<Waypoint> waypoints) {
    for (final waypoint in waypoints) {
      addWaypoint(waypoint, shouldSave: false);
    }
  }
}

typedef _Record = Map<WaypointSymbol, ChartingRecord>;

/// A cached of charted values from Waypoints.
class OldChartingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  OldChartingCache(
    super.valuesBySymbol, {
    required super.fs,
    super.path = defaultCacheFilePath,
  }) : super(
          recordToJson: (_Record r) => r.map(
            (key, value) => MapEntry(
              key.toJson(),
              value.toJson(),
            ),
          ),
        );

  /// Load the charted values from the cache.
  factory OldChartingCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final valuesBySymbol = JsonStore.loadRecord<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              WaypointSymbol.fromJson(key),
              ChartingRecord.fromJson(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    return OldChartingCache(valuesBySymbol, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/charts.json';

  /// The charting records.
  Iterable<ChartingRecord> get records => record.values;
}
