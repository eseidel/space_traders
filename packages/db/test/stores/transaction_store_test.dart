import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('transaction store', (server) {
    test('insert', () async {
      final db = Database.testLive(
        endpoint: await server.endpoint(),
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();
      final transactionStore = TransactionStore(db);
      final transaction = Transaction.fallbackValue();
      await transactionStore.insert(transaction);
      final transactions = await transactionStore.all();
      expect(transactions.length, 1);
      expect(transactions.first, transaction);
    });
  });
}
