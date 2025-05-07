import 'package:db/db.dart';
import 'package:db/src/queries/transaction.dart';
import 'package:db/src/query.dart';
import 'package:types/types.dart';

class TransactionStore {
  TransactionStore(Database db) : _db = db;

  final Database _db;

  /// Insert a transaction into the database.
  Future<void> insert(Transaction transaction) async {
    await _db.execute(insertTransactionQuery(transaction));
  }

  /// Get unique ship symbols from the transaction table.
  Future<Set<ShipSymbol>> uniqueShipSymbolsInTransactions() async {
    final result = await _db.executeSql(
      'SELECT DISTINCT ship_symbol FROM transaction_',
    );
    return result.map((r) => ShipSymbol.fromString(r.first! as String)).toSet();
  }

  /// Get all transactions from the database.
  /// Currently returns in timestamp order, but that may not always be the case.
  Future<Iterable<Transaction>> all() async {
    final result = await _db.executeSql(
      'SELECT * FROM transaction_ ORDER BY timestamp',
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get all transactions matching accountingType from the database.
  Future<Iterable<Transaction>> withAccountingType(
    AccountingType accountingType,
  ) async {
    final result = await _db.execute(
      Query(
        'SELECT * FROM transaction_ WHERE '
        'accounting = @accounting',
        parameters: {'accounting': accountingType.name},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get transactions after a given timestamp.
  /// Returned in ascending timestamp order.
  Future<Iterable<Transaction>> after(DateTime timestamp) async {
    final result = await _db.execute(
      Query(
        'SELECT * FROM transaction_ WHERE timestamp > @timestamp '
        'ORDER BY timestamp',
        parameters: {'timestamp': timestamp},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }

  /// Get the N most recent transactions.
  /// Returned in descending timestamp order.
  Future<Iterable<Transaction>> recent({required int count}) async {
    final result = await _db.execute(
      Query(
        'SELECT * FROM transaction_ ORDER BY timestamp DESC LIMIT @count',
        parameters: {'count': count},
      ),
    );
    return result.map((r) => r.toColumnMap()).map(transactionFromColumnMap);
  }
}
