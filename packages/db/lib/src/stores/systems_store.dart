import 'package:db/db.dart';
import 'package:types/types.dart';

/// Class for reading/writing systems and waypoints to the database.
// TODO(eseidel): Move this down into the db package.
// The only reason this isn't in the db package today is that it calls
// logger, which is currently only available in the cli package.
class SystemsStore {
  /// Create a new [SystemsStore] from the given [db].
  SystemsStore(Database db) : _db = db;

  final Database _db;

  /// Return the [SystemRecord] for the given [symbol].
  Future<SystemRecord?> systemRecordBySymbol(SystemSymbol symbol) async =>
      _db.systemRecordBySymbol(symbol);

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
    return _db.systemWaypointBySymbol(waypointSymbol);
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
    return _db.systemWaypointsBySystemSymbol(systemSymbol);
  }
}
