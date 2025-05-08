import 'package:db/db.dart';
import 'package:db/src/query.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockConnection extends Mock implements pg.Connection {}

class _MockDatabaseConnection extends Mock implements DatabaseConnection {}

class _MockPostgreSQLResult extends Mock implements pg.Result {}

void main() {
  test('defaultDatabase', () async {
    final connection = _MockConnection();
    Future<pg.Connection> openConnection(
      pg.Endpoint endpoint,
      pg.ConnectionSettings? settings,
    ) async {
      expect(endpoint.host, 'localhost');
      return connection;
    }

    final result = _MockPostgreSQLResult();
    when(() => result.isEmpty).thenReturn(true);
    when(() => connection.execute(any())).thenAnswer((_) async => result);
    when(() => connection.runTx<void>(any())).thenAnswer((_) async {});
    when(connection.close).thenAnswer((_) async {});

    final db = await defaultDatabase(openConnection: openConnection);
    expect(db, isNotNull);
    await db.close();
  });

  test('insertTransaction', () {
    final connection = _MockDatabaseConnection();
    final db = Database.test(connection);

    final transaction = Transaction.fallbackValue();
    registerFallbackValue(const Query(''));
    when(() => connection.execute(any())).thenAnswer((_) async {
      return _MockPostgreSQLResult();
    });
    db.transactions.insert(transaction);
    verify(() => connection.execute(any())).called(1);
  });
}
