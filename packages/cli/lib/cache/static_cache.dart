// Cache for server static data that does not typically change
// between resets and thus can be checked into source control.

import 'dart:convert';

import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/compare.dart';
import 'package:collection/collection.dart';

// Not using named parameters to save repetition at call sites.
List<Value> _loadJson<Value>(
  FileSystem fs,
  String path,
  // This is nullable because OpenApi's fromJson are nullable.
  Value? Function(dynamic) valueFromJson,
) {
  return JsonListStore.load(
        fs,
        path,
        (Map<String, dynamic> j) => valueFromJson(j) as Value,
      ) ??
      [];
}

/// A cache of static data that does not typically change between resets and
/// thus can be checked into source control.
abstract class StaticCache<Symbol, Record> extends JsonListStore<Record> {
  /// Creates a new static cache.
  StaticCache(super.map, {required super.fs, required super.path});

  /// The key for the given record.
  Symbol keyFor(Record record);

  /// Copy and normalize the record for comparison and storage.
  Record copyAndNormalize(Record record);

  /// Compare two records.
  int compare(Record a, Record b);

  /// Lookup the entry by its symbol.
  Record? operator [](Symbol symbol) =>
      entries.firstWhereOrNull((record) => keyFor(record) == symbol);

  /// Adds a shipyard ship to the cache.
  void add(Record value, {bool shouldSave = true}) {
    final copy = copyAndNormalize(value);
    final cached = this[keyFor(value)];
    if (cached != null && jsonCompare(cached, copy)) {
      return;
    }
    entries
      ..removeWhere((record) => keyFor(record) == keyFor(copy))
      ..add(copy);

    // This is a minor optimization to allow addAll to only save once.
    if (shouldSave) {
      save();
    }
  }

  /// Adds a list of values to the cache.
  void addAll(Iterable<Record> values) {
    for (final value in values) {
      add(value, shouldSave: false);
    }
    save();
  }

  @override
  void save() {
    // Make sure the entries are always sorted by type to avoid needless
    // diffs in the cache.
    entries.sort(compare);
    super.save();
  }
}

/// A cache of ship mounts.
class ShipMountCache extends StaticCache<ShipMountSymbolEnum, ShipMount> {
  /// Creates a new ship mount cache.
  ShipMountCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load ship mount cache from disk.
  factory ShipMountCache.load(FileSystem fs, {String path = defaultPath}) =>
      ShipMountCache(
        _loadJson(fs, path, ShipMount.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/mounts.json';

  @override
  ShipMount copyAndNormalize(ShipMount record) =>
      ShipMount.fromJson(jsonDecode(jsonEncode(record)))!;

  @override
  int compare(ShipMount a, ShipMount b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipMountSymbolEnum keyFor(ShipMount record) => record.symbol;
}

/// A cache of ship modules.
class ShipModuleCache extends StaticCache<ShipModuleSymbolEnum, ShipModule> {
  /// Creates a new ship module cache.
  ShipModuleCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load ship module cache from disk.
  factory ShipModuleCache.load(FileSystem fs, {String path = defaultPath}) =>
      ShipModuleCache(
        _loadJson(fs, path, ShipModule.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/modules.json';

  @override
  ShipModule copyAndNormalize(ShipModule record) =>
      ShipModule.fromJson(jsonDecode(jsonEncode(record)))!;

  @override
  int compare(ShipModule a, ShipModule b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipModuleSymbolEnum keyFor(ShipModule record) => record.symbol;

  /// Returns the module with the given symbol.
  ShipModule? moduleFromSymbol(ShipModuleSymbolEnum symbol) =>
      entries.firstWhereOrNull((m) => m.symbol == symbol);
}

/// A cache of shipyard ships.
class ShipyardShipCache extends StaticCache<ShipType, ShipyardShip> {
  /// Creates a new shipyard ship cache.
  ShipyardShipCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load shipyard ship cache from disk.
  factory ShipyardShipCache.load(FileSystem fs, {String path = defaultPath}) =>
      ShipyardShipCache(
        _loadJson(fs, path, ShipyardShip.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/shipyard_ships.json';

  @override
  ShipyardShip copyAndNormalize(ShipyardShip record) {
    return ShipyardShip.fromJson(jsonDecode(jsonEncode(record)))!
      ..purchasePrice = 0;
  }

  @override
  int compare(ShipyardShip a, ShipyardShip b) =>
      a.type!.value.compareTo(b.type!.value);

  @override
  ShipType keyFor(ShipyardShip record) => record.type!;
}

/// A cache of ship engines.
class ShipEngineCache extends StaticCache<ShipEngineSymbolEnum, ShipEngine> {
  /// Creates a new ship engine cache.
  ShipEngineCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load ship engine cache from disk.
  factory ShipEngineCache.load(FileSystem fs, {String path = defaultPath}) =>
      ShipEngineCache(
        _loadJson(fs, path, ShipEngine.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/engines.json';

  @override
  ShipEngine copyAndNormalize(ShipEngine record) =>
      ShipEngine.fromJson(jsonDecode(jsonEncode(record)))!;

  @override
  int compare(ShipEngine a, ShipEngine b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipEngineSymbolEnum keyFor(ShipEngine record) => record.symbol;
}

/// A cache of ship reactors.
class ShipReactorCache extends StaticCache<ShipReactorSymbolEnum, ShipReactor> {
  /// Creates a new ship reactor cache.
  ShipReactorCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load ship reactor cache from disk.
  factory ShipReactorCache.load(FileSystem fs, {String path = defaultPath}) =>
      ShipReactorCache(
        _loadJson(fs, path, ShipReactor.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/reactors.json';

  @override
  ShipReactor copyAndNormalize(ShipReactor record) =>
      ShipReactor.fromJson(jsonDecode(jsonEncode(record)))!;

  @override
  int compare(ShipReactor a, ShipReactor b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  ShipReactorSymbolEnum keyFor(ShipReactor record) => record.symbol;
}

/// A cache of waypoint traits.
class WaypointTraitCache
    extends StaticCache<WaypointTraitSymbolEnum, WaypointTrait> {
  /// Creates a new waypoint trait cache.
  WaypointTraitCache(super.map, {required super.fs, super.path = defaultPath});

  /// Load waypoint trait cache from disk.
  factory WaypointTraitCache.load(FileSystem fs, {String path = defaultPath}) =>
      WaypointTraitCache(
        _loadJson(fs, path, WaypointTrait.fromJson),
        fs: fs,
        path: path,
      );

  /// The default path to the cache file.
  static const defaultPath = 'data/waypoint_traits.json';

  @override
  WaypointTrait copyAndNormalize(WaypointTrait record) =>
      WaypointTrait.fromJson(jsonDecode(jsonEncode(record)))!;

  @override
  int compare(WaypointTrait a, WaypointTrait b) =>
      a.symbol.value.compareTo(b.symbol.value);

  @override
  WaypointTraitSymbolEnum keyFor(WaypointTrait record) => record.symbol;
}

/// Caches of static server data that does not typically change between
/// resets and thus can be checked into source control.
class StaticCaches {
  /// Creates a new static caches.
  StaticCaches({
    required this.mounts,
    required this.modules,
    required this.shipyardShips,
    required this.engines,
    required this.reactors,
    required this.waypointTraits,
  });

  /// Load the caches from disk.
  factory StaticCaches.load(FileSystem fs) {
    return StaticCaches(
      mounts: ShipMountCache.load(fs),
      modules: ShipModuleCache.load(fs),
      shipyardShips: ShipyardShipCache.load(fs),
      engines: ShipEngineCache.load(fs),
      reactors: ShipReactorCache.load(fs),
      waypointTraits: WaypointTraitCache.load(fs),
    );
  }

  /// The ship mount cache.
  final ShipMountCache mounts;

  /// The ship module cache.
  final ShipModuleCache modules;

  /// The shipyard ship cache.
  final ShipyardShipCache shipyardShips;

  /// The ship engine cache.
  final ShipEngineCache engines;

  /// The ship reactor cache.
  final ShipReactorCache reactors;

  /// The waypoint trait cache.
  final WaypointTraitCache waypointTraits;
}
