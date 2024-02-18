import 'package:cli/api.dart';
import 'package:cli/compare.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Snapshot of contracts in the database.
class ContractSnapshot {
  /// Creates a new contract snapshot.
  ContractSnapshot(this.contracts);

  /// Load the ContractSnapshot from the database.
  static Future<ContractSnapshot> load(Database db) async {
    final contracts = await db.allContracts();
    return ContractSnapshot(contracts.toList());
  }

  /// Contracts in the cache.
  final List<Contract> contracts;

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks = 100;

  int _requestsSinceLastCheck = 0;

  /// Returns a list of all completed contracts.
  List<Contract> get completedContracts =>
      contracts.where((c) => c.fulfilled).toList();

  /// Returns a list of all expired contracts.
  List<Contract> get expiredContracts =>
      contracts.where((c) => c.isExpired && !c.fulfilled).toList();

  /// Returns a list of all active (not fulfilled or expired) contracts.
  List<Contract> get activeContracts =>
      contracts.where((c) => !c.fulfilled && !c.isExpired).toList();

  /// Returns a list of all unaccepted contracts.
  List<Contract> get unacceptedContracts =>
      contracts.where((c) => !c.accepted).toList();

  /// Looks up the contract by id.
  Contract? contract(String id) =>
      contracts.firstWhereOrNull((c) => c.id == id);

  /// Fetches a new snapshot and logs if different from this one.
  // TODO(eseidel): This does not belong in this class.
  Future<ContractSnapshot> ensureUpToDate(Database db, Api api) async {
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck < requestsBetweenChecks) {
      return this;
    }
    _requestsSinceLastCheck = 0;

    final newContracts = await fetchContracts(db, api);
    final newContractsJson =
        newContracts.contracts.map((c) => c.toOpenApi().toJson()).toList();
    final oldContractsJson =
        contracts.map((c) => c.toOpenApi().toJson()).toList();
    // Our contracts class has a timestamp which we don't want to compare, so
    // compare the OpenAPI JSON instead.
    if (jsonMatches(newContractsJson, oldContractsJson)) {
      logger.warn('Contracts changed, updating cache.');
      return newContracts;
    }
    return this;
  }
}

/// Fetches all of the user's contracts.
Future<ContractSnapshot> fetchContracts(Database db, Api api) async {
  final contracts = await allMyContracts(api).toList();
  for (final contract in contracts) {
    await db.upsertContract(contract);
  }
  return ContractSnapshot(contracts);
}
