import 'package:cli/cache/caches.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Static view onto the ConstructionCache.
class ConstructionSnapshot {
  /// Creates a new ConstructionSnapshot.
  ConstructionSnapshot(Iterable<ConstructionRecord> records)
      : _recordForSymbol = records.groupFoldBy(
          (r) => r.waypointSymbol,
          (previous, record) {
            if (previous != null) {
              throw ArgumentError(
                'Duplicate record for ${record.waypointSymbol}!',
              );
            }
            return record;
          },
        );

  final Map<WaypointSymbol, ConstructionRecord> _recordForSymbol;

  /// Loads the ConstructionSnapshot from the database.
  static Future<ConstructionSnapshot> load(Database db) async {
    return ConstructionCache(db).snapshot();
  }

  /// Returns true if we have recent data for the given waypoint symbol.
  bool hasRecentData(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) {
    final record = _recordForSymbol[waypointSymbol];
    if (record == null) {
      return false;
    }
    return record.timestamp.isAfter(DateTime.timestamp().subtract(maxAge));
  }

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  bool? isUnderConstruction(WaypointSymbol waypointSymbol) =>
      _recordForSymbol[waypointSymbol]?.isUnderConstruction;

  /// Gets the Construction for the given waypoint symbol.
  Construction? operator [](WaypointSymbol waypointSymbol) =>
      _recordForSymbol[waypointSymbol]?.construction;

  /// Returns the age of the cache for the given waypoint symbol.
  Duration? cacheAgeFor(WaypointSymbol waypointSymbol) {
    final timestamp = _recordForSymbol[waypointSymbol]?.timestamp;
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
