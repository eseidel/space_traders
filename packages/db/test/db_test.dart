import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _MockPostgreSQLConnection extends Mock implements PostgreSQLConnection {}

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
}
