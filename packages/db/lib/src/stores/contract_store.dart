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

  /// Get a contract by id.
  Future<Contract?> get(String id) async {
    final query = contractByIdQuery(id);
    return _db.queryOne(query, contractFromColumnMap);
  }

  /// Get all contracts which are !accepted.
  Future<Iterable<Contract>> unaccepted() async {
    return _db.queryMany(unacceptedContractsQuery(), contractFromColumnMap);
  }

  /// Get all contracts which are !fulfilled and !expired.
  Future<Iterable<Contract>> active() async {
    return _db.queryMany(activeContractsQuery(), contractFromColumnMap);
  }

  /// Upsert a contract into the database.
  Future<void> upsert(Contract contract) async {
    await _db.execute(upsertContractQuery(contract));
  }
}
