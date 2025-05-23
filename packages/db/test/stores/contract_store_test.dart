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
      const type = ContractType.PROCUREMENT;

      // Not yet accepted, counts as active and unaccepted.
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

      // Expired, never accepted, never fulfilled.
      final expiredBeforeAccept = Contract(
        id: 'expiredBeforeAccept',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          // We would still have time to complete if we had accepted it.
          deadline: now.add(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: false,
        fulfilled: false,
        timestamp: now,
        // We would have had to accept it before now.
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      final expiredAfterAccept = Contract(
        id: 'expiredAfterAccept',
        factionSymbol: faction,
        type: type,
        terms: ContractTerms(
          // Even though accepted, still past the completion deadline.
          deadline: now.subtract(const Duration(days: 1)),
          payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        ),
        accepted: true,
        fulfilled: false,
        timestamp: now,
        deadlineToAccept: now.subtract(const Duration(days: 1)),
      );

      /// Accepted, past acceptance deadline. Active, not yet fulfilled.
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
      final fulfilled = Contract(
        id: 'fulfilled',
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
      await db.contracts.upsert(expiredBeforeAccept);
      await db.contracts.upsert(expiredAfterAccept);
      await db.contracts.upsert(acceptedPastDeadline);
      await db.contracts.upsert(fulfilled);
      // Contract does not implement equals, so we check the id.
      expect(
        (await db.contracts.get(unaccepted.id))!.id,
        equals(unaccepted.id),
      );

      Set<String> ids(Iterable<Contract> contracts) =>
          contracts.map((c) => c.id).toSet();

      // Expired shows up in all, but not in unaccepted or active.
      expect(await db.contracts.all(), hasLength(5));
      final snapshot = await db.contracts.snapshotAll();
      expect(snapshot.length, 5);
      expect(snapshot.completedContracts, hasLength(1));
      expect(snapshot.expiredContracts, hasLength(2));
      expect(snapshot.activeContracts, hasLength(2));
      expect(snapshot.unacceptedContracts, hasLength(1));

      expect(await db.contracts.unaccepted(), hasLength(1));
      expect(ids(await db.contracts.active()), {
        'unaccepted',
        'acceptedPastDeadline',
      });

      unaccepted.accepted = true;
      await db.contracts.upsert(unaccepted);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(ids(await db.contracts.active()), {
        'unaccepted',
        'acceptedPastDeadline',
      });
      unaccepted.fulfilled = true;
      await db.contracts.upsert(unaccepted);
      expect(await db.contracts.unaccepted(), isEmpty);
      expect(ids(await db.contracts.active()), {'acceptedPastDeadline'});
    });
  });
}
