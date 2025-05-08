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
      const antimatter = TradeSymbol.ANTIMATTER;
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
        final inOtherSystem = await db.marketListings.inSystem(otherSystem);
        expect(inOtherSystem.length, equals(0));

        final all = await db.marketListings.all();
        expect(all.length, equals(1));
        expect(all.first, equals(marketListing));
      });

      test('which trades', () async {
        // Makes most tests fit on one line.
        final listings = db.marketListings;
        final system = waypointSymbol.system;
        expect(await listings.whichTrades(importSymbol), isFalse);

        await listings.upsert(marketListing);

        final whichImports = await listings.withImportsInSystem(
          system,
          importSymbol,
        );
        expect(whichImports.length, equals(1));
        expect(whichImports.first, equals(waypointSymbol));

        final notImported = await listings.withImportsInSystem(
          system,
          exportSymbol,
        );
        expect(notImported.length, equals(0));

        expect(await listings.whichTrades(importSymbol), isTrue);
        expect(await listings.whichTrades(exportSymbol), isTrue);
        expect(await listings.whichTrades(exchangeSymbol), isTrue);
        expect(await listings.whichTrades(antimatter), isFalse);
      });
    });
  });
}
