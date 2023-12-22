import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// A cached of construction values from Waypoints.
class OldConstructionCache extends JsonListStore<ConstructionRecord> {
  /// Creates a new construction cache.
  OldConstructionCache(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Load the Construction values from the cache.
  factory OldConstructionCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final records = JsonListStore.loadRecords<ConstructionRecord>(
          fs,
          path,
          ConstructionRecord.fromJson,
        ) ??
        [];
    return OldConstructionCache(records, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/construction.json';

  /// The Construction values.
  List<ConstructionRecord> get values => records;
}

/// Static view onto the ConstructionCache.
class ConstructionSnapshot {
  /// Creates a new ConstructionSnapshot.
  ConstructionSnapshot(Iterable<ConstructionRecord> records)
      : _records = records.toList();

  final List<ConstructionRecord> _records;

  /// Loads the ConstructionSnapshot from the database.
  static Future<ConstructionSnapshot> load(Database db) async {
    return ConstructionCache(db).snapshot();
  }

  /// Gets the ConstructionRecord for the given waypoint symbol.
  ConstructionRecord? _recordForSymbol(WaypointSymbol waypointSymbol) =>
      _records.firstWhereOrNull(
        (record) => record.waypointSymbol == waypointSymbol,
      );

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  bool? isUnderConstruction(WaypointSymbol waypointSymbol) =>
      _recordForSymbol(waypointSymbol)?.isUnderConstruction;

  /// Gets the Construction for the given waypoint symbol.
  Construction? operator [](WaypointSymbol waypointSymbol) =>
      _recordForSymbol(waypointSymbol)?.construction;

  /// Returns the age of the cache for the given waypoint symbol.
  Duration? cacheAgeFor(WaypointSymbol waypointSymbol) {
    final timestamp = _recordForSymbol(waypointSymbol)?.timestamp;
    if (timestamp == null) {
      return null;
    }
    return DateTime.timestamp().difference(timestamp);
  }
}

/// Helper for constructing a ConstructionSnapshot.
extension ConstructionCacheSnapshot on ConstructionCache {
  /// Creates a new ConstructionSnapshot.
  Future<ConstructionSnapshot> snapshot() async {
    return ConstructionSnapshot(await allRecords());
  }
}
