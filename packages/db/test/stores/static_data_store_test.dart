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
        await store.addAll([shipMount]);
        expect(await store.get(shipMount.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipModules', () async {
        final store = db.shipModules;
        expect(store, isA<ShipModuleStore>());
        final shipModule = testShipModule();
        await store.addAll([shipModule]);
        expect(await store.get(shipModule.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipyardShips', () async {
        final store = db.shipyardShips;
        expect(store, isA<ShipyardShipStore>());
        final shipyardShip = testShipyardShip();
        await store.addAll([shipyardShip]);
        expect(await store.get(shipyardShip.type), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipEngines', () async {
        final store = db.shipEngines;
        expect(store, isA<ShipEngineStore>());
        final shipEngine = testShipEngine();
        await store.addAll([shipEngine]);
        expect(await store.get(shipEngine.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('shipReactors', () async {
        final store = db.shipReactors;
        expect(store, isA<ShipReactorStore>());
        final shipReactor = testShipReactor();
        await store.addAll([shipReactor]);
        expect(await store.get(shipReactor.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('waypointTraits', () async {
        final store = db.waypointTraits;
        expect(store, isA<WaypointTraitStore>());
        final waypointTrait = testWaypointTrait();
        await store.addAll([waypointTrait]);
        expect(await store.get(waypointTrait.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('tradeGoods', () async {
        final store = db.tradeGoods;
        expect(store, isA<TradeGoodStore>());
        final tradeGood = testTradeGood();
        await store.addAll([tradeGood]);
        expect(await store.get(tradeGood.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('tradeExports', () async {
        final store = db.tradeExports;
        expect(store, isA<TradeExportStore>());
        final tradeExport = testTradeExport();
        await store.addAll([tradeExport]);
        expect(await store.get(tradeExport.export), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });

      test('events', () async {
        final store = db.events;
        expect(store, isA<EventStore>());
        final event = testShipConditionEvent();
        await store.addAll([event]);
        expect(await store.get(event.symbol), isNotNull);
        expect(await store.snapshot(), hasLength(1));
      });
    });
  });
}
