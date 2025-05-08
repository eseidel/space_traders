import 'package:db/db.dart';
import 'package:db/src/queries/behavior.dart';
import 'package:types/types.dart';

/// A store for contracts.
class BehaviorStore {
  /// Create a new contract store.
  BehaviorStore(this._db);

  final Database _db;

  /// Get all behavior states.
  Future<Iterable<BehaviorState>> all() async {
    return _db.queryMany(allBehaviorStatesQuery(), behaviorStateFromColumnMap);
  }

  /// Get all behavior states with the given behavior type.
  Future<Iterable<BehaviorState>> ofType(Behavior behavior) async {
    final query = behaviorStatesWithBehaviorQuery(behavior);
    return _db.queryMany(query, behaviorStateFromColumnMap);
  }

  /// Get a behavior state by ship symbol.
  Future<BehaviorState?> get(ShipSymbol shipSymbol) async {
    final query = behaviorBySymbolQuery(shipSymbol);
    return _db.queryOne(query, behaviorStateFromColumnMap);
  }

  /// Get a behavior state by symbol.
  Future<void> upsert(BehaviorState behaviorState) async {
    await _db.execute(upsertBehaviorStateQuery(behaviorState));
  }

  /// Delete a behavior state.
  Future<void> delete(ShipSymbol shipSymbol) async {
    await _db.execute(deleteBehaviorQuery(shipSymbol));
  }
}
