import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('system', (server) {
    test('get and set', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final system = SystemRecord(
        symbol: SystemSymbol.fromString('W-A'),
        waypointSymbols: const [],
        type: SystemType.RED_STAR,
        position: const SystemPosition(0, 0),
      );
      await db.upsertSystemRecord(system);
      final system2 = await db.systemRecordBySymbol(system.symbol);
      expect(system2, equals(system));
    });
  });
}
