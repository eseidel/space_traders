import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/third_party/compare.dart';

// TODO(eseidel): Share code with _shipListsMatch.
bool _contractListsMatch(List<Contract> actual, List<Contract> expected) {
  if (actual.length != expected.length) {
    logger.info(
      "Contract list lengths don't match: "
      '${actual.length} != ${expected.length}',
    );
    return false;
  }

  for (var i = 0; i < actual.length; i++) {
    final diff = findDifferenceBetweenStrings(
      jsonEncode(actual[i].toJson()),
      jsonEncode(expected[i].toJson()),
    );
    if (diff != null) {
      logger.info('Contract list differs at index $i: ${diff.which}');
      return false;
    }
  }
  return true;
}

/// In-memory cache of contacts.
class ContractCache {
  /// Creates a new contract cache.
  ContractCache(this.contracts, {this.requestsBetweenChecks = 100});

  /// Creates a new ShipCache from the API.
  static Future<ContractCache> load(Api api) async =>
      ContractCache(await allMyContracts(api).toList());

  /// Contracts in the cache.
  final List<Contract> contracts;

  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks;

  int _requestsSinceLastCheck = 0;

  /// Ensures the contracts in the cache are up to date.
  Future<void> ensureContractsUpToDate(Api api) async {
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck < requestsBetweenChecks) {
      return;
    }
    final newContracts = await allMyContracts(api).toList();
    _requestsSinceLastCheck = 0;
    // This check races with the code in continueNavigationIfNeeded which
    // knows how to update the ShipNavStatus from IN_TRANSIT to IN_ORBIT when
    // a ship has arrived.  We could add some special logic here to ignore
    // that false positive.  This check is called at the top of every loop
    // and might notice that a ship has arrived before the ship logic gets
    // to run and update the status.
    if (_contractListsMatch(contracts, newContracts)) {
      return;
    }
    logger.warn('Contract list changed, updating cache.');
    updateContracts(contracts);
  }

  /// Updates the contracts in the cache.
  void updateContracts(List<Contract> newContracts) {
    contracts
      ..clear()
      ..addAll(newContracts);
  }

  /// Updates a single contract in the cache.
  void updateContract(Contract contract) {
    final index = contracts.indexWhere((c) => c.id == contract.id);
    if (index == -1) {
      contracts.add(contract);
    } else {
      contracts[index] = contract;
    }
  }

  /// Returns a list of all active (not fulfilled or expired) contracts.
  List<Contract> get activeContracts =>
      contracts.where((c) => !c.fulfilled && !c.isExpired).toList();

  /// Returns a list of all unaccepted contracts.
  List<Contract> get unacceptedContracts =>
      contracts.where((c) => !c.accepted).toList();

  /// Looks up the contract by id.
  Contract? contract(String id) => contracts.firstWhere((c) => c.id == id);
}
