import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:cli/cache/waypoint_traits.dart';
import 'package:meta/meta.dart';

/// A charted value.
@immutable
class ChartedValues {
  /// Creates a new charted values.
  const ChartedValues({
    required this.waypointSymbol,
    required this.chart,
    required this.faction,
    required this.traitSymbols,
    required this.orbitals,
  });

  /// Creates a new charted values from JSON data.
  factory ChartedValues.fromJson(Map<String, dynamic> json) {
    final orbitals = (json['orbitals'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map((j) => WaypointOrbital.fromJson(j)!)
        .toList();
    final faction =
        WaypointFaction.fromJson(json['faction'] as Map<String, dynamic>?);
    final traitSymbols = _loadTraitSymbols(json);
    final chart = Chart.fromJson(json['chart'] as Map<String, dynamic>)!;
    return ChartedValues(
      waypointSymbol: json['waypointSymbol'] as String,
      orbitals: orbitals,
      faction: faction,
      traitSymbols: traitSymbols,
      chart: chart,
    );
  }

  static List<WaypointTraitSymbolEnum> _loadTraitSymbols(
    Map<String, dynamic> json,
  ) {
    final maybeNames = json['traitSymbols'] as List<dynamic>?;
    if (maybeNames == null) {
      return (json['traits'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((j) => WaypointTrait.fromJson(j)!.symbol)
          .toList();
    }
    return maybeNames
        .cast<String>()
        .map((e) => WaypointTraitSymbolEnum.fromJson(e)!)
        .toList();
  }

  /// Symbol for this waypoint.
  final String waypointSymbol;

  /// Waypoints that orbit this waypoint.
  // TODO(eseidel): It's not clear if we should store orbitals. I think they're
  // computable from the SystemsCache.
  final List<WaypointOrbital> orbitals;

  /// Faction for this waypoint.
  final WaypointFaction? faction;

  /// The traits of the waypoint.
  final List<WaypointTraitSymbolEnum> traitSymbols;

  /// Chart for this waypoint.
  final Chart chart;

  /// Converts this charted values to JSON data.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'waypointSymbol': waypointSymbol,
        'orbitals': orbitals.map((o) => o.toJson()).toList(),
        'faction': faction?.toJson(),
        'traitSymbols': traitSymbols.map((e) => e.value).toList(),
        'chart': chart.toJson(),
      };
}

typedef _Record = Map<String, ChartedValues>;

/// A cached of charted values from Waypoints.
class ChartingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  ChartingCache(
    super.valuesBySymbol,
    this.waypointTraits, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/charts.json';

  /// The cache of waypoint traits.
  final WaypointTraitCache waypointTraits;

  /// Load the charted values from the cache.
  // TODO(eseidel): Maybe this should be a constructor?
  // ignore: prefer_constructors_over_static_methods
  static ChartingCache load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final valuesBySymbol = JsonStore.load<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              key,
              ChartedValues.fromJson(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    final waypointTraits = WaypointTraitCache.load(fs);
    return ChartingCache(valuesBySymbol, waypointTraits, fs: fs, path: path);
  }

  /// The charted values by waypoint symbol.
  Map<String, ChartedValues> get _valuesBySymbol => record;

  /// The charted values.
  @visibleForTesting
  Iterable<ChartedValues> get values => _valuesBySymbol.values;

  /// The number of waypoints in the cache.
  int get waypointCount => _valuesBySymbol.length;

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
      waypointSymbol: waypoint.symbol,
      orbitals: waypoint.orbitals,
      faction: waypoint.faction,
      traitSymbols: waypoint.traits.map((e) => e.symbol).toList(),
      chart: chart,
    );
    waypointTraits.addTraits(waypoint.traits);
    _valuesBySymbol[waypoint.symbol] = chartedValues;
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
  ChartedValues? valuesForSymbol(String waypointSymbol) =>
      _valuesBySymbol[waypointSymbol];

  /// Sythesizes a waypoint from cached values if possible.
  Waypoint? waypointFromSymbol(
    SystemsCache systemsCache,
    String waypointSymbol,
  ) {
    final values = valuesForSymbol(waypointSymbol);
    if (values == null) {
      return null;
    }
    final systemWaypoint = systemsCache.waypointFromSymbol(waypointSymbol);
    final traits = values.traitSymbols
        .map(waypointTraits.traitFromSymbol)
        .whereType<WaypointTrait>()
        .toList();
    return Waypoint(
      symbol: systemWaypoint.symbol,
      type: systemWaypoint.type,
      systemSymbol: systemWaypoint.systemSymbol.system,
      x: systemWaypoint.x,
      y: systemWaypoint.y,
      chart: values.chart,
      faction: values.faction,
      orbitals: values.orbitals,
      traits: traits,
    );
  }
}
