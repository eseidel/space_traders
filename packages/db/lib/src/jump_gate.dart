import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query all jump gates.
Query allJumpGatesQuery() => const Query(
      'SELECT * FROM jump_gate_',
      parameters: {},
    );

/// Upsert a jump gate.
Query upsertJumpGateQuery(JumpGate jumpGate) => Query(
      '''
      INSERT INTO jump_gate_ (
        symbol,
        connections,
      ) VALUES (
        @symbol,
        @connections,
      )
      ON CONFLICT (symbol) DO UPDATE SET
        connections = @connections,
      ''',
      parameters: jumpGateToColumnMap(jumpGate),
    );

/// Get a jump gate by symbol.
Query getJumpGateQuery(WaypointSymbol waypointSymbol) => Query(
      'SELECT * FROM jump_gate_ WHERE symbol = @symbol',
      parameters: {'symbol': waypointSymbol.toJson()},
    );

/// Convert a jump gate to a column map.
Map<String, dynamic> jumpGateToColumnMap(JumpGate jumpGate) {
  return jumpGate.toJson();
}

/// Convert a result row to a jump gate.
JumpGate jumpGateFromColumnMap(Map<String, dynamic> values) {
  return JumpGate.fromJson(values);
}
