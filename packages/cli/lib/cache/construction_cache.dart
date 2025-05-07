import 'package:cli/cli.dart';
import 'package:collection/collection.dart';
import 'package:types/config.dart';

/// Static view onto the ConstructionCache.
class ConstructionSnapshot {
  /// Creates a new ConstructionSnapshot.
  ConstructionSnapshot(Iterable<ConstructionRecord> records)
    : _recordForSymbol = records.groupFoldBy((r) => r.waypointSymbol, (
        previous,
        record,
      ) {
        if (previous != null) {
          throw ArgumentError('Duplicate record for ${record.waypointSymbol}!');
        }
        return record;
      });

  final Map<WaypointSymbol, ConstructionRecord> _recordForSymbol;

  /// Returns all records in the snapshot.
  Iterable<ConstructionRecord> get records => _recordForSymbol.values;

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

// Maybe this should be in db?
/// A cached of construction values from Waypoints.
class ConstructionCache {
  /// Creates a new construction cache.
  ConstructionCache(Database db) : _db = db;

  /// Connection to the database.
  final Database _db;

  /// Load all ConstructionRecords from the database, regardless of age.
  Future<Iterable<ConstructionRecord>> allRecords() async =>
      _db.allConstructionRecords();

  /// Creates a new ConstructionSnapshot from all records, regardless of age.
  Future<ConstructionSnapshot> snapshot() async {
    return ConstructionSnapshot(await allRecords());
  }

  /// Load a ConstructionRecord from the database.
  Future<ConstructionRecord?> getRecord(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => _db.getConstructionRecord(waypointSymbol, maxAge);

  /// Load the Construction value for the given waypoint symbol.
  /// Construction can be null when complete or when we don't know
  /// getConstructionRecord instead to distinguish between the two.
  Future<Construction?> getConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => (await getRecord(waypointSymbol, maxAge: maxAge))?.construction;

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  Future<bool?> isUnderConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async =>
      (await getRecord(waypointSymbol, maxAge: maxAge))?.isUnderConstruction;

  /// Update the construction value for the given waypoint symbol.
  Future<void> updateConstruction(
    WaypointSymbol waypointSymbol,
    Construction? construction,
  ) async {
    final record = ConstructionRecord(
      construction: construction,
      timestamp: DateTime.timestamp(),
      waypointSymbol: waypointSymbol,
    );
    await _db.upsertConstruction(record);
  }
}
