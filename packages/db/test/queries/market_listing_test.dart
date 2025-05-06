import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('market_listing', (server) {
    test('get and set', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      final waypointSymbol = WaypointSymbol.fromString('X1-A-1');

      const importSymbol = TradeSymbol.IRON;
      const exportSymbol = TradeSymbol.EXOTIC_MATTER;
      const exchangeSymbol = TradeSymbol.FAB_MATS;

      expect(await db.knowOfMarketWhichTrades(importSymbol), isFalse);

      final marketListing = MarketListing(
        waypointSymbol: waypointSymbol,
        imports: const {importSymbol},
        exports: const {exportSymbol},
        exchange: const {exchangeSymbol},
      );
      await db.upsertMarketListing(marketListing);

      expect(await db.knowOfMarketWhichTrades(importSymbol), isTrue);
      expect(await db.knowOfMarketWhichTrades(exportSymbol), isTrue);
      expect(await db.knowOfMarketWhichTrades(exchangeSymbol), isTrue);
      expect(await db.knowOfMarketWhichTrades(TradeSymbol.ANTIMATTER), isFalse);

      final result = await db.marketListingAt(waypointSymbol);
      expect(result, equals(marketListing));

      final all = await db.allMarketListings();
      expect(all.length, equals(1));
      expect(all.first, equals(marketListing));
    });
  });
}
