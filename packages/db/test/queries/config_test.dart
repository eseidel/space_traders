import 'package:db/db.dart';
import 'package:test/test.dart';

import '../docker.dart';

void main() {
  withPostgresServer('config', (server) {
    group('get and set', () {
      late Database db;
      setUpAll(() async {
        final endpoint = await server.endpoint();
        db = Database.testLive(
          endpoint: endpoint,
          connection: await server.newConnection(),
        );
        await db.migrateToLatestSchema();
      });

      test('agent symbol', () async {
        expect(await db.getAgentSymbol(), isNull);
        const agentSymbol = 'S';
        await db.setAgentSymbol(agentSymbol);
        expect(await db.getAgentSymbol(), equals(agentSymbol));
      });

      test('auth token', () async {
        expect(await db.getAuthToken(), isNull);
        const token = '1234567890';
        await db.setAuthToken(token);
        expect(await db.getAuthToken(), equals(token));
      });
    });
  });
}
