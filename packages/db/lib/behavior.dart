import 'package:db/query.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Query a ship behavior state by symbol.
Query behaviorBySymbolQuery(ShipSymbol shipSymbol) => Query(
      'SELECT * FROM behavior_ WHERE ship_symbol = @ship_symbol',
      substitutionValues: {
        'ship_symbol': shipSymbol.toString(),
      },
    );

/// Convert a BehaviorState to a column map.
Map<String, dynamic> behaviorStateToColumnMap(BehaviorState state) => {
      'ship_symbol': state.shipSymbol.toString(),
      'json': state.toJson(),
    };

/// Convert a result row to a BehaviorState.
BehaviorState behaviorStateFromResultRow(PostgreSQLResultRow row) {
  final values = row.toColumnMap();
  return BehaviorState.fromJson(values['json'] as Map<String, dynamic>);
}
