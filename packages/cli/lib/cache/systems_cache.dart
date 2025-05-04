import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// A list of systems.
class SystemsSnapshot {
  /// Create a new [SystemsSnapshot] with the given [systems].
  SystemsSnapshot(this.systems)
    : _index = Map.fromEntries(systems.map((e) => MapEntry(e.symbol, e)));

  /// Create a new [SystemsSnapshot] from the given [db].
  static Future<SystemsSnapshot> load(Database db) async {
    // Load all SystemRecords.
    // Load all SystemWaypoints.
    // Assemble them into Systems.
    final systemRecords = await db.allSystemRecords();
    final waypoints = await db.allSystemWaypoints();
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

  /// All systems in this snapshot.
  final List<System> systems;

  final Map<SystemSymbol, System> _index;

  /// Return the jump gate waypoint for the given [symbol].
  // Systems currently only have one jumpgate, but if that ever
  // changes all callers of this method might be wrong.
  SystemWaypoint? jumpGateWaypointForSystem(SystemSymbol symbol) =>
      this[symbol].waypoints.firstWhereOrNull((w) => w.isJumpGate);

  /// Return the system with the given [symbol].
  /// Exposed for passing to lists for mapping.
  System systemBySymbol(SystemSymbol symbol) =>
      _index[symbol] ?? (throw ArgumentError('Unknown system $symbol'));

  /// Return the system with the given [symbol].
  System operator [](SystemSymbol symbol) => systemBySymbol(symbol);

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  SystemWaypoint? waypointOrNull(WaypointSymbol waypointSymbol) {
    final waypoints = waypointsInSystem(waypointSymbol.system);
    return waypoints.firstWhereOrNull((w) => w.symbol == waypointSymbol);
  }

  /// Return the SystemWaypoint for the given [symbol].
  SystemWaypoint waypoint(WaypointSymbol symbol) => waypointOrNull(symbol)!;

  /// Return the SystemWaypoint for the given [symbol].
  SystemWaypoint? waypointFromString(String symbol) =>
      waypointOrNull(WaypointSymbol.fromString(symbol));

  /// Returns true if the given [symbol] is a jump gate.
  bool isJumpGate(WaypointSymbol symbol) => waypoint(symbol).isJumpGate;

  /// Return the SystemWaypoints for the given [systemSymbol].
  List<SystemWaypoint> waypointsInSystem(SystemSymbol systemSymbol) =>
      this[systemSymbol].waypoints;
}

/// A list of systems.
class SystemsCache {
  /// Create a new [SystemsCache] from the given [db].
  SystemsCache(Database db) : _db = db;

  final Database _db;

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
    return await _db.systemWaypointsBySystemSymbol(systemSymbol);
  }
}
