import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

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
        expect(await db.config.getAgentSymbol(), isNull);
        const agentSymbol = 'S';
        await db.config.setAgentSymbol(agentSymbol);
        expect(await db.config.getAgentSymbol(), equals(agentSymbol));
      });

      test('auth token', () async {
        expect(await db.config.getAuthToken(), isNull);
        const token = '1234567890';
        await db.config.setAuthToken(token);
        expect(await db.config.getAuthToken(), equals(token));
      });

      test('game phase', () async {
        expect(await db.config.getGamePhase(), isNull);
        const phase = GamePhase.selloff;
        await db.config.setGamePhase(phase);
        expect(await db.config.getGamePhase(), equals(phase));
      });
    });
  });
}
