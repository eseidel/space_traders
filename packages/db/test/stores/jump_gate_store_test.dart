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

      final symbol = WaypointSymbol.fromString('X-A-A');
      final connections = {WaypointSymbol.fromString('X-B-B')};
      final jumpGate = JumpGate(
        waypointSymbol: symbol,
        connections: connections,
      );
      await db.jumpGates.upsert(jumpGate);

      final retrieved = await db.jumpGates.get(symbol);
      expect(retrieved, jumpGate);

      final snapshot = await db.jumpGates.snapshotAll();
      expect(snapshot.forSymbol(symbol), jumpGate);
    });
  });
}
