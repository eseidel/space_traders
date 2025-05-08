import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('shipyard_listing_store', (server) {
    test('smoke test', () async {
      final db = Database.testLive(
        endpoint: await server.endpoint(),
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final shipyardListing = ShipyardListing.fallbackValue();
      await db.shipyardListings.upsert(shipyardListing);
      final shipyardListings = await db.shipyardListings.all();
      expect(shipyardListings.length, equals(1));
      expect(shipyardListings.first, equals(shipyardListing));
    });
  });
}
