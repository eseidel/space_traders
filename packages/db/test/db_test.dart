import 'package:db/db.dart';
import 'package:db/transaction.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockPostgreSQLConnection extends Mock implements PostgreSQLConnection {}

class _MockDatabaseConfig extends Mock implements DatabaseConfig {}

class _MockPostgreSQLResult extends Mock implements PostgreSQLResult {}

void main() {
  test('defaultDatabase', () async {
    final connection = _MockPostgreSQLConnection();
    PostgreSQLConnection createConnection(DatabaseConfig config) {
      expect(config.host, 'localhost');
      return connection;
    }

    when(connection.open).thenAnswer((_) async {});
    when(connection.close).thenAnswer((_) async {});

    final db = await defaultDatabase(createConnection: createConnection);
    expect(db, isNotNull);
    await db.close();
  });

  test('createConnectionFromConfig', () {
    final config = DatabaseConfig(
      host: 'host',
      port: 1234,
      database: 'database',
      username: 'username',
      password: 'password',
    );
    final connection = connectionFromConfig(config);
    expect(connection.host, config.host);
  });

  test('insertTransaction', () {
    final connection = _MockPostgreSQLConnection();
    final config = _MockDatabaseConfig();
    final db = Database(config, createConnection: (_) => connection);

    final transaction = Transaction.fallbackValue();
    when(
      () => connection.query(
        any(),
        substitutionValues: any(named: 'substitutionValues'),
      ),
    ).thenAnswer((_) async {
      return _MockPostgreSQLResult();
    });
    db.insertTransaction(transaction);
    verify(
      () => connection.query(
        'INSERT INTO transaction_ (transaction_type, ship_symbol, '
        'waypoint_symbol, trade_symbol, ship_type, quantity, trade_type, '
        'per_unit_price, timestamp, agent_credits, accounting) '
        'VALUES (@transaction_type, @ship_symbol, @waypoint_symbol, '
        '@trade_symbol, @ship_type, @quantity, @trade_type, @per_unit_price, '
        '@timestamp, @agent_credits, @accounting)',
        substitutionValues: transactionToColumnMap(transaction),
      ),
    ).called(1);
  });
}
