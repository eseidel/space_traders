import 'package:db/transaction.dart';
import 'package:postgres/postgres.dart';

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<Database> defaultDatabase() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'spacetraders',
    username: 'postgres',
    password: 'password',
    timeoutInSeconds: 1,
  );
  await connection.open();
  return Database(connection);
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.connection);

  /// Insert a transaction into the database.
  Future<void> insertTransaction(TransactionRecord record) async {
    final query = insertTransactionQuery(record);
    await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
  }

  /// The underlying connection.
  // TODO(eseidel): This shoudn't be public.
  // Make it private and move all callers into the db package.
  final PostgreSQLConnection connection;

  /// Open the database connection.
  Future<void> open() => connection.open();

  /// Close the database connection.
  Future<void> close() => connection.close();

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await connection.query('LISTEN $channel');
  }
}
