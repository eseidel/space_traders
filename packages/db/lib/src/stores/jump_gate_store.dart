import 'package:db/db.dart';
import 'package:db/src/queries/jump_gate.dart';
import 'package:types/types.dart';

/// Store for jump gates.
class JumpGateStore {
  /// Create a new jump gate store.
  JumpGateStore(this._db);

  final Database _db;

  /// Get all jump gates from the database.
  Future<Iterable<JumpGate>> all() async =>
      _db.queryMany(allJumpGatesQuery(), jumpGateFromColumnMap);

  /// Get a snapshot of all jump gates from the database.
  Future<JumpGateSnapshot> snapshotAll() async =>
      JumpGateSnapshot((await all()).toList());

  /// Add a jump gate to the database.
  Future<void> upsert(JumpGate jumpGate) async =>
      _db.execute(upsertJumpGateQuery(jumpGate));

  /// Get the jump gate for the given waypoint symbol.
  Future<JumpGate?> get(WaypointSymbol waypointSymbol) async =>
      _db.queryOne(getJumpGateQuery(waypointSymbol), jumpGateFromColumnMap);
}
