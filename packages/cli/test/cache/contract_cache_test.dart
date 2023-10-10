import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

void main() {
  test('ContractCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final api = _MockApi();
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final contract = Contract(
      id: 'id',
      factionSymbol: 'faction',
      type: ContractTypeEnum.PROCUREMENT,
      terms: ContractTerms(
        deadline: moonLanding,
        payment: ContractPayment(onAccepted: 1000, onFulfilled: 1000),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'T',
            destinationSymbol: 'W',
            unitsFulfilled: 0,
            unitsRequired: 10,
          ),
        ],
      ),
      expiration: moonLanding,
      deadlineToAccept: moonLanding,
    );
    final contracts = [contract];
    ContractCache(contracts, fs: fs).save();
    final contractCache2 = await ContractCache.load(api, fs: fs);
    expect(contractCache2.contracts.length, contracts.length);
    // Contract.toJson doesn't recurse (openapi gen bug), so use jsonEncode.
    expect(
      jsonEncode(contractCache2.contracts.first),
      jsonEncode(contracts.first),
    );

    // If the system clock is ever before the moon landing, some of these
    // may fail.
    expect(contractCache2.completedContracts, isEmpty);
    expect(contractCache2.unacceptedContracts.length, 1);

    expect(contractCache2.activeContracts, isEmpty);
    expect(contractCache2.expiredContracts.length, 1);
    // Contract == isn't implemented, so we would need to use
    // contractCache if we wanted the same object.  Instead we check id.
    expect(contractCache2.expiredContracts.first.id, contracts.first.id);
    expect(
      contractCache2.contract(contract.id)?.factionSymbol,
      contract.factionSymbol,
    );
    expect(contractCache2.contract('nope'), isNull);

    final updatedContract = Contract(
      id: 'id',
      factionSymbol: 'faction2',
      type: ContractTypeEnum.PROCUREMENT,
      terms: ContractTerms(
        deadline: moonLanding,
        payment: ContractPayment(onAccepted: 1000, onFulfilled: 1000),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'T',
            destinationSymbol: 'W',
            unitsFulfilled: 0,
            unitsRequired: 10,
          ),
        ],
      ),
      expiration: moonLanding,
      deadlineToAccept: moonLanding,
    );
    contractCache2.updateContract(updatedContract);
    expect(contractCache2.contracts.length, contracts.length);
    expect(
      contractCache2.contract(contract.id)?.factionSymbol,
      updatedContract.factionSymbol,
    );
  });
}
