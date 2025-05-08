import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('extraction_store', (server) {
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

      test('insert', () async {
        final now = DateTime.timestamp();
        final extraction = ExtractionRecord(
          timestamp: now,
          shipSymbol: ShipSymbol.fromString('A-1'),
          waypointSymbol: WaypointSymbol.fromString('X1-B-4'),
          tradeSymbol: TradeSymbol.DIAMONDS,
          power: 100,
          surveySignature: 'survey',
          quantity: 100,
        );
        await db.extractions.insert(extraction);

        final extractions = await db.extractions.all();
        expect(extractions.length, 1);
        expect(extractions.first.timestamp, now);
        expect(extractions.first.tradeSymbol, TradeSymbol.DIAMONDS);
        expect(extractions.first.quantity, 100);
      });
    });
  });
}
