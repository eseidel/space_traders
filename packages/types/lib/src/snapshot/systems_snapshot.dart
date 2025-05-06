import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A list of systems.
class SystemsSnapshot {
  /// Create a new [SystemsSnapshot] with the given [systems].
  SystemsSnapshot(List<System> systems)
    : _index = Map.fromEntries(systems.map((e) => MapEntry(e.symbol, e)));

  /// All systems in this snapshot.
  Iterable<System> get systems => _index.values;

  /// All system records in this snapshot.
  // TODO(eseidel): records should be cheaper than systems to call.
  Iterable<SystemRecord> get records => systems.map((s) => s.toSystemRecord());

  final Map<SystemSymbol, System> _index;

  /// Number of systems in the snapshot.
  int get systemsCount => _index.values.length;

  /// Number of waypoints in the snapshot.
  int get waypointsCount => _index.values.expand((s) => s.waypoints).length;

  /// Return the jump gate waypoint for the given [symbol].
  // Systems currently only have one jumpgate, but if that ever
  // changes all callers of this method might be wrong.
  SystemWaypoint? jumpGateWaypointForSystem(SystemSymbol symbol) =>
      _index[symbol]!.waypoints.firstWhereOrNull((w) => w.isJumpGate);

  /// Return the jump gate symbol for the given [symbol].
  WaypointSymbol? jumpGateSymbolForSystem(SystemSymbol symbol) =>
      jumpGateWaypointForSystem(symbol)?.symbol;

  /// Return true if the given [symbol] has a jump gate.
  bool hasJumpGate(SystemSymbol symbol) =>
      jumpGateWaypointForSystem(symbol) != null;

  /// Return the system with the given [symbol].
  /// Exposed for passing to lists for mapping.
  System systemBySymbol(SystemSymbol symbol) =>
      _index[symbol] ?? (throw ArgumentError('Unknown system $symbol'));

  /// Return the system record with the given [symbol].
  SystemRecord systemRecordBySymbol(SystemSymbol symbol) =>
      _index[symbol]!.toSystemRecord();

  /// Return all systems within the given [radius] of the given [position].
  Iterable<System> systemsWithinRadius(
    SystemPosition position,
    double radius,
  ) => systems.where((s) => s.position.distanceTo(position) < radius);

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
      _index[systemSymbol]!.waypoints;
}
