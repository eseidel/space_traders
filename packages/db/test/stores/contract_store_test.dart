import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('contract_store', (server) {
    test('smoke test', () async {
      final db = Database.testLive(
        endpoint: await server.endpoint(),
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final terms = ContractTerms(
        deadline: DateTime.now(),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
      );

      final contract = Contract.test(
        id: 'foo',
        terms: terms,
        accepted: false,
        fulfilled: false,
      );

      final now = DateTime.timestamp();
      final expired = Contract.test(
        id: 'expired',
        terms: terms,
        accepted: false,
        fulfilled: false,
        timestamp: now,
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isEmpty);

      await db.contracts.upsert(contract);
      await db.contracts.upsert(expired);

      // Contract does not implement equals, so we check the id.
      expect((await db.contracts.get(contract.id))!.id, equals(contract.id));

      // Expired shows up in all, but not in unaccepted or active.
      expect(await db.contracts.all(), hasLength(2));
      expect(await db.contracts.unaccepted(), hasLength(1));
      expect(await db.contracts.active(), hasLength(1));

      contract.accepted = true;
      await db.contracts.upsert(contract);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isNotEmpty);

      contract.fulfilled = true;
      await db.contracts.upsert(contract);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isEmpty);
    });
  });
}
