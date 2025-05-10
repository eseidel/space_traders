import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Snapshot of contracts in the database.
class ContractSnapshot {
  /// Creates a new contract snapshot.
  ContractSnapshot(this.contracts);

  /// Contracts in the cache.
  final List<Contract> contracts;

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
}
