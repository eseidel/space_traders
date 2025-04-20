import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Query all behavior states.
Query allBehaviorStatesQuery() => const Query('SELECT * FROM behavior_');

/// Query a ship behavior state by symbol.
Query behaviorBySymbolQuery(ShipSymbol shipSymbol) => Query(
  'SELECT * FROM behavior_ WHERE ship_symbol = @ship_symbol',
  parameters: {'ship_symbol': shipSymbol.toJson()},
);

/// Query behavior states with a specified behavior.
Query behaviorStatesWithBehaviorQuery(Behavior behavior) => Query(
  'SELECT * FROM behavior_ WHERE behavior = @behavior',
  parameters: {'behavior': behavior.toJson()},
);

/// Query to insert or update a behavior state.
Query upsertBehaviorStateQuery(BehaviorState state) => Query(
  '''
      INSERT INTO behavior_ (ship_symbol, behavior, json)
      VALUES (@ship_symbol, @behavior, @json)
      ON CONFLICT (ship_symbol) DO UPDATE SET
        behavior = @behavior,
        json = @json
      ''',
  parameters: {
    'ship_symbol': state.shipSymbol.toJson(),
    'behavior': state.behavior.toJson(),
    'json': state.toJson(),
  },
);

/// Query to delete a behavior state.
Query deleteBehaviorStateQuery(ShipSymbol shipSymbol) => Query(
  'DELETE FROM behavior_ WHERE ship_symbol = @ship_symbol',
  parameters: {'ship_symbol': shipSymbol.toJson()},
);

/// Convert a BehaviorState to a column map.
Map<String, dynamic> behaviorStateToColumnMap(BehaviorState state) => {
  'ship_symbol': state.shipSymbol.toJson(),
  'behavior': state.behavior.toJson(),
  'json': state.toJson(),
};

/// Convert a result row to a BehaviorState.
BehaviorState behaviorStateFromColumnMap(Map<String, dynamic> values) {
  // Ignoring ship_symbol and behavior as they are duplicated in the json.
  return BehaviorState.fromJson(values['json'] as Map<String, dynamic>);
}
