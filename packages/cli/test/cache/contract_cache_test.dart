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
          )
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
  });
}
