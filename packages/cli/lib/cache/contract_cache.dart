import 'package:cli/api.dart';
import 'package:cli/cache/response_cache.dart';
import 'package:cli/net/queries.dart';
import 'package:file/file.dart';

/// In-memory cache of contacts.
class ContractCache extends ResponseListCache<Contract> {
  /// Creates a new contract cache.
  ContractCache(
    super.contracts, {
    super.checkEvery = 100,
    super.fs,
    super.path = defaultPath,
  }) : super(
          entryToJson: (c) => c.toJson(),
          refreshEntries: (Api api) => allMyContracts(api).toList(),
        );

  /// Creates a new ContractCache from the Api or FileSystem if provided.
  static Future<ContractCache> load(
    Api api, {
    FileSystem? fs,
    String path = defaultPath,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && fs != null) {
      final contracts = ResponseListCache.load<Contract>(
        fs,
        path,
        (j) => Contract.fromJson(j)!,
      );
      if (contracts != null) {
        return ContractCache(contracts, fs: fs, path: path);
      }
    }
    final contracts = await allMyContracts(api).toList();
    return ContractCache(contracts, fs: fs, path: path);
  }

  /// The default path to the contracts cache.
  static const String defaultPath = 'data/contracts.json';

  /// Contracts in the cache.
  List<Contract> get contracts => entries;

  /// Updates a single contract in the cache.
  Future<void> updateContract(Contract contract) async {
    final index = contracts.indexWhere((c) => c.id == contract.id);
    if (index == -1) {
      contracts.add(contract);
    } else {
      contracts[index] = contract;
    }
    await save();
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
