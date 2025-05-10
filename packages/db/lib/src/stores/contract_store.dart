import 'package:db/db.dart';
import 'package:db/src/queries/contract.dart';
import 'package:types/types.dart';

/// A store for contracts.
class ContractStore {
  /// Create a new contract store.
  ContractStore(this._db);

  final Database _db;

  /// Get all contracts from the database.
  Future<Iterable<Contract>> all() async {
    return _db.queryMany(allContractsQuery(), contractFromColumnMap);
  }

  /// Get a snapshot of all contracts.
  Future<ContractSnapshot> snapshotAll() async {
    final contracts = await all();
    return ContractSnapshot(contracts.toList());
  }

  /// Get a contract by id.
  Future<Contract?> get(String id) async {
    final query = contractByIdQuery(id);
    return _db.queryOne(query, contractFromColumnMap);
  }

  /// Get all contracts which are !accepted and !expired.
  Future<Iterable<Contract>> unaccepted() async {
    final now = DateTime.timestamp();
    return _db.queryMany(unacceptedContractsQuery(now), contractFromColumnMap);
  }

  /// Get all contracts which are !fulfilled and !expired.
  Future<Iterable<Contract>> active() async {
    final now = DateTime.timestamp();
    return _db.queryMany(activeContractsQuery(now), contractFromColumnMap);
  }

  /// Upsert a contract into the database.
  Future<void> upsert(Contract contract) async {
    await _db.execute(upsertContractQuery(contract));
  }
}
