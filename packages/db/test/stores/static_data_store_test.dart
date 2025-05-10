import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('static_data', (server) {
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
      test('accessors', () async {
        expect(db.shipMounts, isA<ShipMountStore>());
        expect(await db.shipMounts.snapshot(), isA<ShipMountSnapshot>());

        expect(db.shipModules, isA<ShipModuleStore>());
        expect(await db.shipModules.snapshot(), isA<ShipModuleSnapshot>());

        expect(db.shipyardShips, isA<ShipyardShipStore>());
        expect(await db.shipyardShips.snapshot(), isA<ShipyardShipSnapshot>());

        expect(db.shipEngines, isA<ShipEngineStore>());
        expect(await db.shipEngines.snapshot(), isA<ShipEngineSnapshot>());

        expect(db.shipReactors, isA<ShipReactorStore>());
        expect(await db.shipReactors.snapshot(), isA<ShipReactorSnapshot>());

        expect(db.waypointTraits, isA<WaypointTraitStore>());
        expect(
          await db.waypointTraits.snapshot(),
          isA<WaypointTraitSnapshot>(),
        );

        expect(db.tradeGoods, isA<TradeGoodStore>());
        expect(await db.tradeGoods.snapshot(), isA<TradeGoodSnapshot>());

        expect(db.tradeExports, isA<TradeExportStore>());
        expect(await db.tradeExports.snapshot(), isA<TradeExportSnapshot>());

        expect(db.events, isA<EventStore>());
        expect(await db.events.snapshot(), isA<EventSnapshot>());
      });
    });
  });
}
