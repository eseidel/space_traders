import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import 'docker.dart';

void main() {
  withPostgresServer('market_price', (server) {
    test('get and set', () async {
      final endpoint = await server.endpoint();
      final db = Database.testLive(
        endpoint: endpoint,
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();

      // upsertMarketPrice currently treats all time as UTC.
      // We might want to fix that, but for now just use utc.
      final timestamp = DateTime(2021).toUtc();

      final waypointSymbol = WaypointSymbol.fromString('X1-A-1');
      const tradeSymbol = TradeSymbol.IRON;
      final marketPrice = MarketPrice(
        waypointSymbol: waypointSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 100,
        tradeVolume: 100,
        timestamp: timestamp,
      );
      await db.upsertMarketPrice(marketPrice);

      final result = await db.marketPriceAt(waypointSymbol, tradeSymbol);
      expect(result, equals(marketPrice));

      final all = await db.allMarketPrices();
      expect(all.length, equals(1));
      expect(all.first, equals(marketPrice));

      final system = SystemSymbol.fromString('X1-A');
      final systemPrices = await db.marketPricesInSystem(system);
      expect(systemPrices.length, equals(1));
      expect(systemPrices.first, equals(marketPrice));

      final median = await db.medianMarketPurchasePrice(tradeSymbol);
      expect(median, equals(100));
    });
  });
}
