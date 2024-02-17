import 'package:db/db.dart';
import 'package:db/transaction.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockConnection extends Mock implements pg.Connection {}

class _MockPostgreSQLResult extends Mock implements pg.Result {}

void main() {
  test('defaultDatabase', () async {
    final connection = _MockConnection();
    Future<pg.Connection> openConnection(pg.Endpoint endpoint) async {
      expect(endpoint.host, 'localhost');
      return connection;
    }

    when(connection.close).thenAnswer((_) async {});

    final db = await defaultDatabase(openConnection: openConnection);
    expect(db, isNotNull);
    await db.close();
  });

  test('insertTransaction', () {
    final connection = _MockConnection();
    final db = Database.test(connection);

    final transaction = Transaction.fallbackValue();
    when(
      () => connection.execute(
        any(),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {
      return _MockPostgreSQLResult();
    });
    db.insertTransaction(transaction);
    verify(
      () => connection.execute(
        'INSERT INTO transaction_ (transaction_type, ship_symbol, '
        'waypoint_symbol, trade_symbol, ship_type, quantity, trade_type, '
        'per_unit_price, timestamp, agent_credits, accounting) '
        'VALUES (@transaction_type, @ship_symbol, @waypoint_symbol, '
        '@trade_symbol, @ship_type, @quantity, @trade_type, @per_unit_price, '
        '@timestamp, @agent_credits, @accounting)',
        parameters: transactionToColumnMap(transaction),
      ),
    ).called(1);
  });
}
