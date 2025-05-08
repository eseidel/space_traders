import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('market_listing', (server) {
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

      final waypointSymbol = WaypointSymbol.fromString('X1-A-1');
      const importSymbol = TradeSymbol.IRON;
      const exportSymbol = TradeSymbol.EXOTIC_MATTER;
      const exchangeSymbol = TradeSymbol.FAB_MATS;
      final marketListing = MarketListing(
        waypointSymbol: waypointSymbol,
        imports: const {importSymbol},
        exports: const {exportSymbol},
        exchange: const {exchangeSymbol},
      );

      test('get and set', () async {
        await db.marketListings.upsert(marketListing);

        final result = await db.marketListings.at(waypointSymbol);
        expect(result, equals(marketListing));

        final listingsInSystem = await db.marketListings.inSystem(
          waypointSymbol.system,
        );
        expect(listingsInSystem.length, equals(1));
        expect(listingsInSystem.first, equals(marketListing));

        final otherSystem = SystemSymbol.fromString('X1-B');
        final listingsInOtherSystem = await db.marketListings.inSystem(
          otherSystem,
        );
        expect(listingsInOtherSystem.length, equals(0));

        final all = await db.marketListings.all();
        expect(all.length, equals(1));
        expect(all.first, equals(marketListing));
      });

      test('which trades', () async {
        expect(
          await db.marketListings.knowOfMarketWhichTrades(importSymbol),
          isFalse,
        );

        await db.marketListings.upsert(marketListing);

        final whichImports = await db.marketListings.marketsWithImportInSystem(
          waypointSymbol.system,
          importSymbol,
        );
        expect(whichImports.length, equals(1));
        expect(whichImports.first, equals(waypointSymbol));

        final whichImportsEmpty = await db.marketListings
            .marketsWithImportInSystem(waypointSymbol.system, exportSymbol);
        expect(whichImportsEmpty.length, equals(0));

        expect(
          await db.marketListings.knowOfMarketWhichTrades(importSymbol),
          isTrue,
        );
        expect(
          await db.marketListings.knowOfMarketWhichTrades(exportSymbol),
          isTrue,
        );
        expect(
          await db.marketListings.knowOfMarketWhichTrades(exchangeSymbol),
          isTrue,
        );
        expect(
          await db.marketListings.knowOfMarketWhichTrades(
            TradeSymbol.ANTIMATTER,
          ),
          isFalse,
        );
      });
    });
  });
}
