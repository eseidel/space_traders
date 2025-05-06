import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('ship', (server) {
    test('get and set', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final symbol = ShipSymbol.fromString('S-1234567890');
      final ship = Ship.test(symbol);
      await db.upsertShip(ship);
      final result = await db.getShip(symbol);
      expect(result!.symbol, equals(ship.symbol));
      await db.deleteShip(symbol);
      expect(await db.getShip(symbol), isNull);
    });
  });
}
