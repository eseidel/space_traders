import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Extension to add a [systems] getter to the [Database] class.
// This should just be on Database.
extension SystemsStoreAccessor on Database {
  /// Get the [SystemsStore] for the database.
  SystemsStore get systems => SystemsStore(this);
}

/// Class for reading/writing systems and waypoints to the database.
// TODO(eseidel): Move this down into the db package.
// The only reason this isn't in the db package today is that it calls
// logger, which is currently only available in the cli package.
class SystemsStore {
  /// Create a new [SystemsStore] from the given [db].
  SystemsStore(Database db) : _db = db;

  final Database _db;

  /// Create a new [SystemsSnapshot] from all the data in the database.
  Future<SystemsSnapshot> snapshot() async {
    final systemRecords = await _db.allSystemRecords();
    final waypoints = await _db.allSystemWaypoints();
    final grouped = waypoints.groupListsBy((w) => w.system);
    final systems =
        systemRecords.map((r) {
          final waypoints = grouped[r.symbol] ?? [];
          if (waypoints.length != r.waypointSymbols.length) {
            logger.warn('Waypoints length mismatch for system ${r.symbol}');
          }
          return System.fromRecord(r, waypoints);
        }).toList();
    return SystemsSnapshot(systems);
  }

  /// Upsert a [System] into the database.
  Future<void> upsertSystem(System system) async {
    // We could do this in a transaction, but for now not bothering.
    await _db.upsertSystemRecord(system.toSystemRecord());
    for (final waypoint in system.waypoints) {
      await _db.upsertSystemWaypoint(waypoint);
    }
  }

  /// Return the [SystemRecord] for the given [symbol].
  Future<SystemRecord?> systemRecordBySymbol(SystemSymbol symbol) async =>
      await _db.systemRecordBySymbol(symbol);

  /// Return the jump gate waypoint for the given [symbol].
  // Systems currently only have one jumpgate, but if that ever
  // changes all callers of this method might be wrong.
  Future<SystemWaypoint?> jumpGateWaypointForSystem(SystemSymbol symbol) async {
    final waypoints = await _db.systemWaypointsBySystemSymbolAndType(
      symbol,
      WaypointType.JUMP_GATE,
    );
    return waypoints.firstOrNull;
  }

  /// Return the jump gate symbol for the given system [symbol].
  Future<WaypointSymbol?> jumpGateSymbolForSystem(SystemSymbol symbol) async {
    final waypoints = await _db.systemWaypointsBySystemSymbolAndType(
      symbol,
      WaypointType.JUMP_GATE,
    );
    return waypoints.firstOrNull?.symbol;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<SystemWaypoint?> waypointOrNull(WaypointSymbol waypointSymbol) async {
    return await _db.systemWaypointBySymbol(waypointSymbol);
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
    return await _db.systemWaypointsBySystemSymbol(systemSymbol);
  }
}
