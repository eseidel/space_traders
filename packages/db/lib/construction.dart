import 'package:db/db.dart';
import 'package:db/query.dart';
import 'package:types/types.dart';

/// Convert a row result into a ConstructionRecord.
ConstructionRecord constructionFromColumnMap(Map<String, dynamic> values) {
  // ignoring is_complete from the db, computing from construction instead.
  return ConstructionRecord(
    construction: Construction.fromJson(values['construction']),
    timestamp: values['timestamp'] as DateTime,
    waypointSymbol:
        WaypointSymbol.fromJson(values['waypoint_symbol'] as String),
  );
}

/// Convert a ConstructionRecord into substitution values for a query.
Map<String, dynamic> constructionToColumnMap(ConstructionRecord survey) {
  return {
    'waypoint_symbol': survey.waypointSymbol.toJson(),
    'construction': survey.construction?.toJson(),
    'timestamp': survey.timestamp,
    'is_complete': !survey.isUnderConstruction,
  };
}

/// Insert or Update a ConstructionRecord into the database.
Query upsertConstructionQuery(ConstructionRecord record) {
  // Insert the ConstructionRecord or update it if it already exists.
  return Query(
    'INSERT INTO construction_ (waypoint_symbol, construction, timestamp, '
    'is_complete) '
    'VALUES (@waypoint_symbol, @construction, @timestamp, @is_complete) '
    'ON CONFLICT (waypoint_symbol) DO UPDATE SET '
    'construction = @construction, '
    'timestamp = @timestamp, '
    'is_complete = @is_complete ',
    substitutionValues: constructionToColumnMap(record),
  );
}

/// Get a ConstructionRecord from the database.
Query getConstructionQuery(WaypointSymbol waypointSymbol, Duration maxAge) {
  return Query(
    'SELECT * FROM construction_ '
    'WHERE waypoint_symbol = @waypoint_symbol '
    'AND timestamp > @timestamp',
    substitutionValues: {
      'waypoint_symbol': waypointSymbol.toJson(),
      'timestamp': DateTime.timestamp().subtract(maxAge),
    },
  );
}

/// Select all ConstructionRecords from the database.
Query allConstructionQuery() {
  return const Query('SELECT * FROM construction_');
}

/// A cached of construction values from Waypoints.
// TODO(eseidel): Rename this ConstructionDb?
class ConstructionCache {
  /// Creates a new construction cache.
  ConstructionCache(Database db) : _db = db;

  /// Connection to the database.
  final Database _db;

  /// Load all ConstructionRecords from the database.
  Future<Iterable<ConstructionRecord>> allRecords() async {
    return _db.allConstructionRecords();
  }

  /// Load a ConstructionRecord from the database.
  Future<ConstructionRecord?> getRecord(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async =>
      _db.getConstruction(waypointSymbol, maxAge);

  /// Load the Construction value for the given waypoint symbol.
  Future<Construction?> getConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    return (await getRecord(waypointSymbol, maxAge: maxAge))?.construction;
  }

  /// Returns the age of the cache for the given waypoint symbol.
  Future<Duration?> cacheAgeFor(WaypointSymbol waypointSymbol) async {
    final timestamp = (await getRecord(waypointSymbol))?.timestamp;
    if (timestamp == null) {
      return null;
    }
    return DateTime.timestamp().difference(timestamp);
  }

  /// Returns true if the given waypoint symbol is under construction.
  /// Returns false if the given waypoint symbol is not under construction.
  /// Returns null if the given waypoint symbol is not in the cache.
  Future<bool?> isUnderConstruction(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    return (await getRecord(waypointSymbol, maxAge: maxAge))
        ?.isUnderConstruction;
  }

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