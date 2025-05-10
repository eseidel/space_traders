import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('construction_store', (server) {
    group('foo', () {
      late Database db;
      setUpAll(() async {
        final endpoint = await server.endpoint();
        db = Database.testLive(
          endpoint: endpoint,
          connection: await server.newConnection(),
        );
        await db.migrateToLatestSchema();
      });

      setUp(() async {
        await db.migrateToSchema(version: 0);
        await db.migrateToLatestSchema();
      });

      test('smoke test', () async {
        final waypointSymbol = WaypointSymbol.fromString('X1-A-W');
        final construction = Construction(
          symbol: waypointSymbol.waypoint,
          isComplete: false,
          materials: [
            ConstructionMaterial(
              tradeSymbol: TradeSymbol.DIAMONDS,
              required_: 10,
              fulfilled: 10,
            ),
          ],
        );
        await db.construction.updateConstruction(waypointSymbol, construction);

        final retrieved = await db.construction.at(waypointSymbol);
        expect(retrieved?.construction?.symbol, waypointSymbol.waypoint);
        expect(retrieved?.construction?.isComplete, false);
        expect(retrieved?.construction?.materials.first.fulfilled, 10);

        expect(await db.construction.isUnderConstruction(waypointSymbol), true);
        expect(
          await db.construction.getConstruction(waypointSymbol),
          isNotNull,
        );

        final otherWaypointSymbol = WaypointSymbol.fromString('X1-B-W');
        expect(
          await db.construction.isUnderConstruction(otherWaypointSymbol),
          isNull,
        );
        expect(
          await db.construction.getConstruction(otherWaypointSymbol),
          isNull,
        );

        final snapshot = await db.construction.snapshotAll();
        expect(snapshot[waypointSymbol], construction);
      });
    });
  });
}
