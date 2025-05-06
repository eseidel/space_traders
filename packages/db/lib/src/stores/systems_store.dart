import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:db/src/queries/system_record.dart';
import 'package:db/src/queries/system_waypoint.dart';
import 'package:types/types.dart';

/// Class for reading/writing systems and waypoints to the database.
// TODO(eseidel): Move this down into the db package.
// The only reason this isn't in the db package today is that it calls
// logger, which is currently only available in the cli package.
class SystemsStore {
  /// Create a new [SystemsStore] from the given [db].
  SystemsStore(Database db) : _db = db;

  final Database _db;

  /// Get all system records from the database.
  Future<Iterable<SystemRecord>> allSystemRecords() async {
    final result = await _db.queryMany(
      allSystemRecordsQuery(),
      systemRecordFromColumnMap,
    );
    return result;
  }

  /// Upsert a system record into the database.
  Future<void> upsertSystemRecord(SystemRecord system) async {
    await _db.execute(upsertSystemRecordQuery(system));
  }

  /// Get a system record by symbol.
  Future<SystemRecord?> systemRecordBySymbol(SystemSymbol symbol) async {
    final query = systemRecordBySymbolQuery(symbol);
    return _db.queryOne(query, systemRecordFromColumnMap);
  }

  /// Get all waypoints from the database.
  /// Returns a list of waypoints.
  Future<Iterable<SystemWaypoint>> allSystemWaypoints() async {
    final result = await _db.queryMany(
      allSystemWaypointsQuery(),
      systemWaypointFromColumnMap,
    );
    return result;
  }

  /// Count the number of system waypoints in the database.
  Future<int> countSystemWaypoints() async {
    final result = await _db.executeSql(
      'SELECT COUNT(*) FROM system_waypoint_',
    );
    return result[0][0]! as int;
  }

  /// Count the number of systems in the database.
  Future<int> countSystemRecords() async {
    final result = await _db.executeSql('SELECT COUNT(*) FROM system_record_');
    return result[0][0]! as int;
  }

  /// Upsert a system waypoint into the database.
  Future<void> upsertSystemWaypoint(SystemWaypoint waypoint) async {
    await _db.execute(upsertSystemWaypointQuery(waypoint));
  }

  /// Get a SystemWaypoint by symbol.
  Future<SystemWaypoint?> systemWaypointBySymbol(WaypointSymbol symbol) async {
    final query = systemWaypointBySymbolQuery(symbol);
    return _db.queryOne(query, systemWaypointFromColumnMap);
  }

  /// Get SystemWaypoints by system symbol.
  Future<Iterable<SystemWaypoint>> systemWaypointsBySystemSymbol(
    SystemSymbol symbol,
  ) async {
    final query = systemWaypointsBySystemQuery(symbol);
    return _db.queryMany(query, systemWaypointFromColumnMap);
  }

  /// Get SystemWaypoints by system symbol and type.
  Future<Iterable<SystemWaypoint>> systemWaypointsBySystemSymbolAndType(
    SystemSymbol symbol,
    WaypointType type,
  ) async {
    final query = systemWaypointsBySystemAndTypeQuery(symbol, type);
    return _db.queryMany(query, systemWaypointFromColumnMap);
  }

  /// Create a new [SystemsSnapshot] from all the data in the database.
  Future<SystemsSnapshot> snapshotAllSystems() async {
    final systemRecords = await allSystemRecords();
    final waypoints = await allSystemWaypoints();
    final grouped = waypoints.groupListsBy((w) => w.system);
    final systems =
        systemRecords.map((r) {
          final waypoints = grouped[r.symbol] ?? [];
          // TODO(eseidel): Log once we have a logger.
          // if (waypoints.length != r.waypointSymbols.length) {
          //   logger.warn('Waypoints length mismatch for system ${r.symbol}');
          // }
          return System.fromRecord(r, waypoints);
        }).toList();
    return SystemsSnapshot(systems);
  }

  /// Upsert a [System] into the database.
  Future<void> upsertSystem(System system) async {
    // We could do this in a transaction, but for now not bothering.
    await upsertSystemRecord(system.toSystemRecord());
    for (final waypoint in system.waypoints) {
      await upsertSystemWaypoint(waypoint);
    }
  }

  /// Return the jump gate waypoint for the given [symbol].
  // Systems currently only have one jumpgate, but if that ever
  // changes all callers of this method might be wrong.
  Future<SystemWaypoint?> jumpGateWaypointForSystem(SystemSymbol symbol) async {
    final waypoints = await systemWaypointsBySystemSymbolAndType(
      symbol,
      WaypointType.JUMP_GATE,
    );
    return waypoints.firstOrNull;
  }

  /// Return the jump gate symbol for the given system [symbol].
  Future<WaypointSymbol?> jumpGateSymbolForSystem(SystemSymbol symbol) async {
    final waypoints = await systemWaypointsBySystemSymbolAndType(
      symbol,
      WaypointType.JUMP_GATE,
    );
    return waypoints.firstOrNull?.symbol;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<SystemWaypoint?> waypointOrNull(WaypointSymbol waypointSymbol) async {
    return systemWaypointBySymbol(waypointSymbol);
  }

  /// Return the SystemWaypoint for the given [symbol].
  Future<WaypointType> waypointType(WaypointSymbol symbol) async =>
      (await waypointOrNull(symbol))!.type;

  /// Return the SystemWaypoint for the given [symbol].
  Future<SystemWaypoint> waypoint(WaypointSymbol symbol) async =>
      (await waypointOrNull(symbol))!;

  /// Returns true if the given [symbol] is a jump gate.
  Future<bool> isJumpGate(WaypointSymbol symbol) async {
    final waypoint = await waypointOrNull(symbol);
    return waypoint != null && waypoint.isJumpGate;
  }

  /// Return the SystemWaypoints for the given [systemSymbol].
  Future<Iterable<SystemWaypoint>> waypointsInSystem(
    SystemSymbol systemSymbol,
  ) async {
    final waypoints = await systemWaypointsBySystemSymbol(systemSymbol);
    return waypoints;
  }
}
