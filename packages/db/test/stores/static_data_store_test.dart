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

      test('shipMounts', () async {
        final store = db.shipMounts;
        expect(store, isA<ShipMountStore>());
        final shipMount = testShipMount();
        await store.add(shipMount);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipModules', () async {
        final store = db.shipModules;
        expect(store, isA<ShipModuleStore>());
        final shipModule = testShipModule();
        await store.add(shipModule);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipyardShips', () async {
        final store = db.shipyardShips;
        expect(store, isA<ShipyardShipStore>());
        final shipyardShip = testShipyardShip();
        await store.add(shipyardShip);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipEngines', () async {
        final store = db.shipEngines;
        expect(store, isA<ShipEngineStore>());
        final shipEngine = testShipEngine();
        await store.add(shipEngine);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipReactors', () async {
        final store = db.shipReactors;
        expect(store, isA<ShipReactorStore>());
        final shipReactor = testShipReactor();
        await store.add(shipReactor);
        expect(await store.snapshot(), hasLength(1));
      });

      test('waypointTraits', () async {
        final store = db.waypointTraits;
        expect(store, isA<WaypointTraitStore>());
        final waypointTrait = testWaypointTrait();
        await store.add(waypointTrait);
        expect(await store.snapshot(), hasLength(1));
      });

      test('tradeGoods', () async {
        final store = db.tradeGoods;
        expect(store, isA<TradeGoodStore>());
        final tradeGood = testTradeGood();
        await store.add(tradeGood);
        expect(await store.snapshot(), hasLength(1));
      });

      test('tradeExports', () async {
        final store = db.tradeExports;
        expect(store, isA<TradeExportStore>());
        final tradeExport = testTradeExport();
        await store.add(tradeExport);
        expect(await store.snapshot(), hasLength(1));
      });

      test('events', () async {
        final store = db.events;
        expect(store, isA<EventStore>());
        final event = testShipConditionEvent();
        await store.add(event);
        expect(await store.snapshot(), hasLength(1));
      });
    });
  });
}
