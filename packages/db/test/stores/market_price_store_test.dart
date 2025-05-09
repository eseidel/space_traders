import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('market_price', (server) {
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
        await db.marketPrices.upsert(marketPrice);

        final result = await db.marketPrices.at(waypointSymbol, tradeSymbol);
        expect(result, equals(marketPrice));

        final all = await db.marketPrices.all();
        expect(all.length, equals(1));
        expect(all.first, equals(marketPrice));

        final allSnapshot = await db.marketPrices.snapshotAll();
        expect(allSnapshot.prices, equals([marketPrice]));

        final system = SystemSymbol.fromString('X1-A');
        final systemPrices = await db.marketPrices.inSystem(system);
        expect(systemPrices.length, equals(1));
        expect(systemPrices.first, equals(marketPrice));

        final systemSnapshot = await db.marketPrices.snapshotInSystem(system);
        expect(systemSnapshot.prices, equals([marketPrice]));

        final median = await db.marketPrices.medianPurchasePrice(tradeSymbol);
        expect(median, equals(100));

        expect(await db.marketPrices.count(), equals(1));
        expect(await db.marketPrices.countWaypoints(), equals(1));
      });

      test('hasRecentAt', () async {
        final waypointSymbol = WaypointSymbol.fromString('X1-A-1');
        final now = DateTime.timestamp();
        final twoDaysAgo = now.subtract(const Duration(days: 2));
        final oldPrice = MarketPrice(
          waypointSymbol: waypointSymbol,
          symbol: TradeSymbol.IRON,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 100,
          tradeVolume: 100,
          timestamp: twoDaysAgo,
        );
        await db.marketPrices.upsert(oldPrice);

        expect(
          await db.marketPrices.at(waypointSymbol, TradeSymbol.IRON),
          equals(oldPrice),
        );

        expect(
          await db.marketPrices.hasRecentAt(
            waypointSymbol,
            const Duration(days: 1),
          ),
          isFalse,
        );

        final oneHourAgo = now.subtract(const Duration(hours: 1));
        final newPrice = MarketPrice(
          waypointSymbol: waypointSymbol,
          symbol: TradeSymbol.IRON,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 100,
          tradeVolume: 100,
          timestamp: oneHourAgo,
        );
        await db.marketPrices.upsert(newPrice);

        expect(
          await db.marketPrices.hasRecentAt(
            waypointSymbol,
            const Duration(days: 1),
          ),
          isTrue,
        );
      });
    });
  });
}
