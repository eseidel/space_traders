import 'package:db/db.dart';
import 'package:db/src/queries/construction.dart';
import 'package:types/config.dart';
import 'package:types/types.dart';

/// Access to the construction records in the database.
class ConstructionStore {
  /// Creates a new construction store.
  ConstructionStore(Database db) : _db = db;

  /// Connection to the database.
  final Database _db;

  /// Get a construction record from the database.
  Future<ConstructionRecord?> at(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => _db.queryOne(
    getConstructionQuery(waypointSymbol, maxAge),
    constructionFromColumnMap,
  );

  /// Return all construction records.
  Future<Iterable<ConstructionRecord>> all() async =>
      _db.queryMany(allConstructionQuery(), constructionFromColumnMap);

  /// Insert a construction record into the database.
  Future<void> upsert(ConstructionRecord record) async =>
      _db.execute(upsertConstructionQuery(record));

  /// Creates a new ConstructionSnapshot from all records, regardless of age.
  Future<ConstructionSnapshot> snapshotAll() async {
    return ConstructionSnapshot(await all());
  }

  /// Load the Construction value for the given waypoint symbol.
  /// Construction can be null when complete or when we don't know
  /// getConstructionRecord instead to distinguish between the two.
  Future<Construction?> getConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => (await at(waypointSymbol, maxAge: maxAge))?.construction;

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  Future<bool?> isUnderConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async => (await at(waypointSymbol, maxAge: maxAge))?.isUnderConstruction;

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
    await upsert(record);
  }
}
