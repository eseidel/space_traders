import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A cached of JumpGate connections.
/// Connections are not necessarily functional, you have to check
/// the ConstructionCache to see if they are under construction.
class JumpGateSnapshot {
  /// Creates a new JumpGate cache.
  JumpGateSnapshot(this.values);

  /// The JumpGate values.
  final List<JumpGate> values;

  /// The number of waypoints in the cache.
  int get waypointCount => values.length;

  /// Gets all jump gates for the given system.
  Iterable<JumpGate> recordsForSystem(SystemSymbol systemSymbol) {
    return values.where(
      (record) => record.waypointSymbol.system == systemSymbol,
    );
  }

  /// Gets the connections for the jump gate with the given symbol.
  Set<WaypointSymbol>? connectionsForSymbol(WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.connections;

  /// Gets the JumpGate for the given waypoint symbol.
  JumpGate? recordForSymbol(WaypointSymbol waypointSymbol) => values
      .firstWhereOrNull((record) => record.waypointSymbol == waypointSymbol);
}
