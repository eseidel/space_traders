import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A charted value.
@immutable
class ChartedValues {
  /// Creates a new charted values.
  const ChartedValues({
    required this.chart,
    required this.faction,
    required this.traitSymbols,
  });

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

// Existing json:
// {
//   "waypointSymbol": "X1-JX78-B11",
//   "faction": {
//    "symbol": "AEGIS"
//   },
//   "traitSymbols": [
//    "MINERAL_DEPOSITS"
//   ],
//   "chart": {
//    "waypointSymbol": null,
//    "submittedBy": "AEGIS",
//    "submittedOn": "2023-12-02T18:47:27.627Z"
//   }
//  }

/// A charted value.
class OldChartedValues {
  /// Creates a new charted values.
  const OldChartedValues({
    required this.waypointSymbol,
    required this.chart,
    required this.faction,
    required this.traitSymbols,
  });

  /// Creates a new charted values from JSON data.
  factory OldChartedValues.fromJson(Map<String, dynamic> json) {
    final faction =
        WaypointFaction.fromJson(json['faction'] as Map<String, dynamic>?);
    final traitSymbols = (json['traitSymbols'] as List<dynamic>)
        .cast<String>()
        .map((e) => WaypointTraitSymbol.fromJson(e)!)
        .toSet();
    final chart = Chart.fromJson(json['chart'] as Map<String, dynamic>)!;
    final waypointSymbol =
        WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    return OldChartedValues(
      waypointSymbol: waypointSymbol,
      faction: faction,
      traitSymbols: traitSymbols,
      chart: chart,
    );
  }

  /// Symbol for this waypoint.
  final WaypointSymbol waypointSymbol;

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
      'waypointSymbol': waypointSymbol.toJson(),
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

/// Temporary shim to allow loading old charting cache.
ChartingRecord compatShim(Map<String, dynamic> json) {
  if (json['timestamp'] != null) {
    return ChartingRecord.fromJson(json);
  }
  final old = OldChartedValues.fromJson(json);
  final values = ChartedValues(
    faction: old.faction,
    traitSymbols: old.traitSymbols,
    chart: old.chart,
  );
  return ChartingRecord(
    waypointSymbol: old.waypointSymbol,
    values: values,
    timestamp: DateTime.timestamp(),
  );
}

typedef _Record = Map<WaypointSymbol, ChartingRecord>;

/// A cached of charted values from Waypoints.
class ChartingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  ChartingCache(
    super.valuesBySymbol,
    this.waypointTraits, {
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
  factory ChartingCache.load(
    FileSystem fs,
    WaypointTraitCache waypointTraits, {
    String path = defaultCacheFilePath,
  }) {
    final valuesBySymbol = JsonStore.loadRecord<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              WaypointSymbol.fromJson(key),
              compatShim(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    return ChartingCache(valuesBySymbol, waypointTraits, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/charts.json';

  /// The cache of waypoint traits.
  final WaypointTraitCache waypointTraits;

  /// The charting record by waypoint symbol.
  Map<WaypointSymbol, ChartingRecord> get _valuesBySymbol => record;

  /// The charting records.
  Iterable<ChartingRecord> get records => _valuesBySymbol.values;

  /// The charted values.
  Iterable<ChartedValues> get values =>
      records.map((e) => e.values).whereNotNull();

  /// The number of waypoints in the cache.
  int get waypointCount => records.length;

  /// The waypoint symbols in the cache.
  Iterable<WaypointSymbol> get waypointSymbols => _valuesBySymbol.keys;

  /// Charting records for the given system.
  Iterable<ChartingRecord> recordsInSystem(SystemSymbol systemSymbol) =>
      records.where((r) => r.waypointSymbol.systemSymbol == systemSymbol);

  /// The waypoint symbols with charts in the given system.
  // If ChartingCache changes to cache negative values (e.g. "no chart")
  // this will need to be updated.
  Iterable<WaypointSymbol> waypointsWithChartInSystem(
    SystemSymbol systemSymbol,
  ) =>
      recordsInSystem(systemSymbol)
          .where((r) => r.isCharted)
          .map((r) => r.waypointSymbol);

  /// Adds a charting record to the cache.
  void addRecord(
    ChartingRecord chartingRecord, {
    bool shouldSave = true,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final waypointSymbol = chartingRecord.waypointSymbol;
    final timestamp = chartingRecord.timestamp;
    if (getNow().isBefore(timestamp)) {
      throw ArgumentError('Bogus timestamp for ChartingRecord for '
          '$waypointSymbol: $timestamp is in '
          'the future.');
    }

    final existingRecord = _valuesBySymbol[waypointSymbol];
    if (existingRecord != null) {
      if (existingRecord.timestamp.isAfter(timestamp)) {
        throw ArgumentError('ChartingRecord for $waypointSymbol: $timestamp is '
            'before existing timestamp: ${existingRecord.timestamp}');
      }
      if (existingRecord.values != null && chartingRecord.values == null) {
        throw ArgumentError('ChartingRecord for $waypointSymbol is already '
            'charted cant remove chart.');
      }
    }

    _valuesBySymbol[chartingRecord.waypointSymbol] = chartingRecord;
    // Minor optimization to allow addWaypoints to only save once.
    if (shouldSave) {
      save();
    }
  }

  /// Adds a waypoint to the cache.
  void addWaypoint(
    Waypoint waypoint, {
    bool shouldSave = true,
    DateTime Function() getNow = defaultGetNow,
  }) {
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
      waypointSymbol: waypoint.waypointSymbol,
      values: chartedValues,
      timestamp: getNow(),
    );
    waypointTraits.addAll(waypoint.traits);
    addRecord(chartingRecord, shouldSave: shouldSave);
  }

  /// Adds a list of waypoints to the cache.
  void addWaypoints(Iterable<Waypoint> waypoints) {
    for (final waypoint in waypoints) {
      addWaypoint(waypoint, shouldSave: false);
    }
    save();
  }

  /// Gets the charting record for the given waypoint symbol.
  ChartingRecord? getRecord(WaypointSymbol waypointSymbol) =>
      _valuesBySymbol[waypointSymbol];

  /// Gets the charted values for the given waypoint symbol.
  ChartedValues? operator [](WaypointSymbol waypointSymbol) =>
      _valuesBySymbol[waypointSymbol]?.values;
}
