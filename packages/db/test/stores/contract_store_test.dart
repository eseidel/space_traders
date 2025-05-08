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
      final contractStore = ContractStore(db);
      final contract = Contract.fallbackValue();
      await contractStore.upsert(contract);
      final contracts = await contractStore.all();
      expect(contracts.length, equals(1));
    });
  });
}
