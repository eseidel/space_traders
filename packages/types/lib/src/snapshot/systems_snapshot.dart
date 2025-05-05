import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A list of systems.
class SystemsSnapshot {
  /// Create a new [SystemsSnapshot] with the given [systems].
  SystemsSnapshot(this.systems)
    : _index = Map.fromEntries(systems.map((e) => MapEntry(e.symbol, e)));

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
