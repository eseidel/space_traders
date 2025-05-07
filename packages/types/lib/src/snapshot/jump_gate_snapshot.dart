import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A snapshot of JumpGate connections.
/// Connections are not necessarily functional, you have to check
/// the ConstructionCache to see if they are under construction.
class JumpGateSnapshot {
  /// Creates a new JumpGate snapshot.
  JumpGateSnapshot(this.values);

  /// The JumpGate values.
  final List<JumpGate> values;

  /// Gets the JumpGate for the given waypoint symbol.
  JumpGate? recordForSymbol(WaypointSymbol waypointSymbol) => values
      .firstWhereOrNull((record) => record.waypointSymbol == waypointSymbol);
}
