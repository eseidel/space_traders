import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A cached of construction values from Waypoints.
class ConstructionCache extends JsonListStore<ConstructionRecord> {
  /// Creates a new construction cache.
  ConstructionCache(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Load the Construction values from the cache.
  factory ConstructionCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final records = JsonListStore.loadRecords<ConstructionRecord>(
          fs,
          path,
          ConstructionRecord.fromJson,
        ) ??
        [];
    return ConstructionCache(records, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/construction.json';

  /// The Construction values.
  List<ConstructionRecord> get values => records;

  /// The number of waypoints in the cache.
  int get waypointCount => values.length;

  /// Updates a [construction] to the cache.
  void updateConstruction({
    required WaypointSymbol waypointSymbol,
    required Construction? construction,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final index = records.indexWhere(
      (record) => record.waypointSymbol == waypointSymbol,
    );

    final newRecord = ConstructionRecord(
      waypointSymbol: waypointSymbol,
      construction: construction,
      timestamp: getNow(),
    );
    if (index >= 0) {
      records[index] = newRecord;
    } else {
      records.add(newRecord);
    }

    save();
  }

  /// Returns all the waypointSymbols under construction.
  Iterable<WaypointSymbol> waypointSymbolsUnderConstruction() => values
      .where((record) => record.isUnderConstruction)
      .map((record) => record.waypointSymbol);

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  bool? isUnderConstruction(WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.isUnderConstruction;

  /// Gets the ConstructionRecord for the given waypoint symbol.
  ConstructionRecord? recordForSymbol(WaypointSymbol waypointSymbol) =>
      values.firstWhereOrNull(
        (record) => record.waypointSymbol == waypointSymbol,
      );

  /// Gets the Construction for the given waypoint symbol.
  Construction? operator [](WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.construction;

  /// Returns the age of the cache for a given waypoint.
  Duration? cacheAgeFor(
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final record = recordForSymbol(waypointSymbol);
    if (record == null) {
      return null;
    }
    return getNow().difference(record.timestamp);
  }
}
