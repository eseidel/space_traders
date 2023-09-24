import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:cli/logger.dart';

typedef _Record = Map<WaypointTraitSymbolEnum, WaypointTrait>;

/// A cache of waypoint traits.
class WaypointTraitCache extends JsonStore<_Record> {
  /// Creates a new waypoint traits cache.
  WaypointTraitCache(
    super.traitsBySymbol, {
    required super.fs,
    super.path = defaultCacheFilePath,
  }) : super(
          recordToJson: (r) =>
              r.map((key, value) => MapEntry(key.toJson(), value.toJson())),
        );

  /// Load waypoint traits from the cache.
  factory WaypointTraitCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final valuesBySymbol = JsonStore.load<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              WaypointTraitSymbolEnum.fromJson(key)!,
              WaypointTrait.fromJson(value as Map<String, dynamic>)!,
            ),
          ),
        ) ??
        {};
    return WaypointTraitCache(valuesBySymbol, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/waypoint_traits.json';

  /// The charted values by waypoint symbol.
  Map<WaypointTraitSymbolEnum, WaypointTrait> get _valuesBySymbol => record;

  /// Lookup the trait for the given symbol.
  WaypointTrait traitFromSymbol(WaypointTraitSymbolEnum symbol) {
    final cached = _valuesBySymbol[symbol];
    if (cached != null) {
      return cached;
    }
    logger.warn('No trait found for symbol: $symbol');
    return WaypointTrait(
      symbol: symbol,
      name: symbol.value,
      description: symbol.value,
    );
  }

  /// Adds a waypoint to the cache.
  void addTrait(WaypointTrait trait, {bool shouldSave = true}) {
    final cached = _valuesBySymbol[trait.symbol];
    if (cached != null &&
        cached.name == trait.name &&
        cached.description == trait.description) {
      return;
    }
    _valuesBySymbol[trait.symbol] = trait;
    // This is just a minor optimization to allow addWaypoints to only
    // save once.
    if (shouldSave) {
      save();
    }
  }

  /// Adds a list of traits to the cache.
  void addTraits(Iterable<WaypointTrait> traits) {
    for (final trait in traits) {
      addTrait(trait, shouldSave: false);
    }
    save();
  }

  /// Gets the WaypointTrait for the given symbol.
  WaypointTrait? traitForSymbol(WaypointTraitSymbolEnum traitSymbol) =>
      _valuesBySymbol[traitSymbol];
}
