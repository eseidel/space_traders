import 'package:db/db.dart';
import 'package:test/test.dart';

import 'docker.dart';

void main() {
  withPostgresServer('config', (server) {
    test('get and set agent symbol', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();
      expect(await db.getAgentSymbol(), isNull);
      const agentSymbol = 'S';
      await db.setAgentSymbol(agentSymbol);
      expect(await db.getAgentSymbol(), equals(agentSymbol));
    });
  });
}
