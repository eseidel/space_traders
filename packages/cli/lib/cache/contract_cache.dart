import 'package:cli/api.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/net/queries.dart';

/// In-memory cache of contacts.
class ContractCache extends ResponseListCache<Contract> {
  /// Creates a new contract cache.
  ContractCache(super.contracts, {super.checkEvery = 100})
      : super(
          entryToJson: (c) => c.toJson(),
          refreshEntries: (Api api) => allMyContracts(api).toList(),
        );

  /// Creates a new ContractCache from the API.
  static Future<ContractCache> load(Api api) async =>
      ContractCache(await allMyContracts(api).toList());

  /// Contracts in the cache.
  List<Contract> get contracts => entries;

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
