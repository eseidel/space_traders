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

      final waypointSymbol = WaypointSymbol.fromString('A-B-C');
      final shipyardListing = ShipyardListing(
        waypointSymbol: waypointSymbol,
        shipTypes: const {ShipType.EXPLORER},
      );
      await db.shipyardListings.upsert(shipyardListing);

      expect(
        await db.shipyardListings.at(waypointSymbol),
        equals(shipyardListing),
      );

      final shipyardListings = await db.shipyardListings.all();
      expect(shipyardListings.length, equals(1));
      expect(shipyardListings.first, equals(shipyardListing));

      final snapshot = await db.shipyardListings.snapshotAll();
      expect(snapshot.listings.length, equals(1));
      expect(snapshot.at(waypointSymbol), equals(shipyardListing));
    });
  });
}
