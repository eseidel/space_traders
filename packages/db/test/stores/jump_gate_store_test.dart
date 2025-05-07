import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() async {
  withPostgresServer('JumpGateStore', (server) async {
    test('smoke test', () async {
      final db = Database.testLive(
        endpoint: await server.endpoint(),
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();
      final jumpGateStore = JumpGateStore(db);
      final jumpGate = JumpGate(
        waypointSymbol: WaypointSymbol.fromString('X-A-A'),
        connections: {WaypointSymbol.fromString('X-B-B')},
      );
      await jumpGateStore.upsert(jumpGate);
      final snapshot = await jumpGateStore.snapshotAll();
      expect(snapshot.waypointCount, 1);
      expect(
        snapshot.recordForSymbol(WaypointSymbol.fromString('X-A-A')),
        jumpGate,
      );
    });
  });
}
