import 'package:db/transaction.dart';
import 'package:test/test.dart';
import 'package:types/transaction.dart';

void main() {
  test('Transaction round trip', () {
    final transaction = Transaction.fallbackValue();
    final map = transactionToColumnMap(transaction);
    final newTransaction = transactionFromColumnMap(map);
    expect(newTransaction, equals(transaction));
  });
}
