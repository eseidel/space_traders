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

      final now = DateTime.timestamp();

      const faction = 'faction';
      const type = ContractTypeEnum.PROCUREMENT;

      // unaccepted, not active.
      final unaccepted = Contract(
        id: 'unaccepted',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          deadline: now.add(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: false,
        fulfilled: false,
        timestamp: now,
        deadlineToAccept: now.add(const Duration(days: 1)),
      );

      // expired, not unaccepted, not active.
      final expired = Contract(
        id: 'expired',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          // Out of time, but not complete.
          deadline: now.add(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: false,
        fulfilled: false,
        timestamp: now,
        // We could have accepted it if we had not already.
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      /// accepted, active, not fulfilled.
      final acceptedPastDeadline = Contract(
        id: 'acceptedPastDeadline',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          // Not complete, but not out of time yet.
          deadline: now.add(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: true,
        fulfilled: false,
        timestamp: now,
        // But we could no longer accept it if we had not already.
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      /// accepted, fulfilled (thus not active), not expired.
      final fullfilled = Contract(
        id: 'fullfilled',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          deadline: now.add(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: true,
        fulfilled: true,
        timestamp: now,
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isEmpty);

      await db.contracts.upsert(unaccepted);
      await db.contracts.upsert(expired);
      await db.contracts.upsert(acceptedPastDeadline);
      await db.contracts.upsert(fullfilled);
      // Contract does not implement equals, so we check the id.
      expect(
        (await db.contracts.get(unaccepted.id))!.id,
        equals(unaccepted.id),
      );

      // Expired shows up in all, but not in unaccepted or active.
      expect(await db.contracts.all(), hasLength(4));
      expect(await db.contracts.unaccepted(), hasLength(1));
      final active = await db.contracts.active();
      for (final c in active) {
        print(c.toJson());
      }
      expect(active, hasLength(1));

      unaccepted.accepted = true;
      await db.contracts.upsert(unaccepted);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isNotEmpty);

      unaccepted.fulfilled = true;
      await db.contracts.upsert(unaccepted);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(await db.contracts.active(), isEmpty);
    });
  });
}
