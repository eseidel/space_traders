import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query all behavior states.
Query allBehaviorStatesQuery() => const Query('SELECT * FROM behavior_');

/// Query a ship behavior state by symbol.
Query behaviorBySymbolQuery(ShipSymbol shipSymbol) => Query(
      'SELECT * FROM behavior_ WHERE ship_symbol = @ship_symbol',
      parameters: {
        'ship_symbol': shipSymbol.toJson(),
      },
    );

/// Query to insert or update a behavior state.
Query upsertBehaviorStateQuery(BehaviorState state) => Query(
      '''
      INSERT INTO behavior_ (ship_symbol, json)
      VALUES (@ship_symbol, @json)
      ON CONFLICT (ship_symbol) DO UPDATE SET json = @json
      ''',
      parameters: {
        'ship_symbol': state.shipSymbol.toJson(),
        'json': state.toJson(),
      },
    );

/// Query to delete a behavior state.
Query deleteBehaviorStateQuery(ShipSymbol shipSymbol) => Query(
      'DELETE FROM behavior_ WHERE ship_symbol = @ship_symbol',
      parameters: {
        'ship_symbol': shipSymbol.toJson(),
      },
    );

/// Convert a BehaviorState to a column map.
Map<String, dynamic> behaviorStateToColumnMap(BehaviorState state) => {
      'ship_symbol': state.shipSymbol.toJson(),
      'json': state.toJson(),
    };

/// Convert a result row to a BehaviorState.
BehaviorState behaviorStateFromColumnMap(Map<String, dynamic> values) {
  return BehaviorState.fromJson(values['json'] as Map<String, dynamic>);
}
