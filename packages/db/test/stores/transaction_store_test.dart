import 'package:db/db.dart';
import 'package:db/src/queries/transaction.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('transaction store', (server) {
    test('smoke test', () async {
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

      final after = await transactionStore.after(
        transaction.timestamp.subtract(const Duration(seconds: 1)),
      );
      expect(after.length, 1);
      expect(after.first, transaction);

      final before = await transactionStore.recent(count: 1);
      expect(before.length, 1);
      expect(before.first, transaction);

      final uniqueShipSymbols =
          await transactionStore.uniqueShipSymbolsInTransactions();
      expect(uniqueShipSymbols.length, 1);
      expect(uniqueShipSymbols.first, transaction.shipSymbol);

      final transactionsWithAccountingType = await transactionStore
          .withAccountingType(transaction.accounting);
      expect(transactionsWithAccountingType.length, 1);
      expect(transactionsWithAccountingType.first, transaction);
    });
  });

  test('Transaction round trip', () {
    final transaction = Transaction.fallbackValue();

    final map = transactionToColumnMap(transaction);
    final newTransaction = transactionFromColumnMap(map);
    expect(newTransaction, equals(transaction));
  });
}
