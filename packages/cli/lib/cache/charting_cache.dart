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
    required this.waypointSymbol,
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
    final waypointSymbol =
        WaypointSymbol.fromJson(json['waypointSymbol'] as String);
    return ChartedValues(
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

typedef _Record = Map<WaypointSymbol, ChartedValues>;

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
              ChartedValues.fromJson(value as Map<String, dynamic>),
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

  /// The charted values by waypoint symbol.
  Map<WaypointSymbol, ChartedValues> get _valuesBySymbol => record;

  /// The charted values.
  Iterable<ChartedValues> get values => _valuesBySymbol.values;

  /// The number of waypoints in the cache.
  int get waypointCount => _valuesBySymbol.length;

  /// The waypoint symbols in the cache.
  Iterable<WaypointSymbol> get waypointSymbols => _valuesBySymbol.keys;

  /// The waypoint symbols with charts in the given system.
  // If ChartingCache changes to cache negative values (e.g. "no chart")
  // this will need to be updated.
  Iterable<WaypointSymbol> waypointsWithChartInSystem(
    SystemSymbol systemSymbol,
  ) =>
      waypointSymbols.where((s) => s.systemSymbol == systemSymbol);

  /// Adds a waypoint to the cache.
  void addWaypoint(Waypoint waypoint, {bool shouldSave = true}) {
    final chart = waypoint.chart;
    // These should either all by null or all be non-null.
    // We only store non-null values, e.g. waypoints which have already
    // been charted.
    if (chart == null) {
      return;
    }
    final chartedValues = ChartedValues(
      waypointSymbol: waypoint.waypointSymbol,
      faction: waypoint.faction,
      traitSymbols: waypoint.traits.map((e) => e.symbol).toSet(),
      chart: chart,
    );
    waypointTraits.addAll(waypoint.traits);
    _valuesBySymbol[waypoint.waypointSymbol] = chartedValues;
    // This is just a minor optimization to allow addWaypoints to only
    // save once.
    if (shouldSave) {
      save();
    }
  }

  /// Adds a list of waypoints to the cache.
  void addWaypoints(Iterable<Waypoint> waypoints) {
    for (final waypoint in waypoints) {
      addWaypoint(waypoint, shouldSave: false);
    }
    save();
  }

  /// Gets the charted values for the given waypoint symbol.
  ChartedValues? operator [](WaypointSymbol waypointSymbol) =>
      _valuesBySymbol[waypointSymbol];
}
