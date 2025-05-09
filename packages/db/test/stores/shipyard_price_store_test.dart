import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('shipyard_price', (server) {
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

      test('get and set', () async {
        final store = db.shipyardPrices;
        final price = ShipyardPrice.fallbackValue();
        await store.upsert(price);
        final result = await store.at(price.waypointSymbol, price.shipType);
        expect(result, equals(price));

        final snapshot = await store.snapshotAll();
        expect(snapshot.prices.length, equals(1));
        expect(snapshot.prices.first, equals(price));

        final all = await store.all();
        expect(all.length, equals(1));
        expect(all.first, equals(price));
      });

      test('hasRecent', () async {
        final store = db.shipyardPrices;
        final price = ShipyardPrice.fallbackValue();
        await store.upsert(price);
        final result = await store.hasRecent(
          price.waypointSymbol,
          const Duration(days: 1),
        );
        expect(result, equals(true));
      });

      test('count', () async {
        final store = db.shipyardPrices;
        final price = ShipyardPrice.fallbackValue();
        await store.upsert(price);
        final result = await store.count();
        expect(result, equals(1));
        final waypointCount = await store.waypointCount();
        expect(waypointCount, equals(1));
      });
    });
  });
}
