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

      test('which buys', () async {
        final listings = db.marketListings;
        final system = waypointSymbol.system;

        await db.marketListings.upsert(marketListing);

        final importBuys = await listings.whichBuysInSystem(
          system,
          importSymbol,
        );
        expect(importBuys.toSet(), equals({waypointSymbol}));

        final exchangeBuys = await listings.whichBuysInSystem(
          system,
          exchangeSymbol,
        );
        expect(exchangeBuys.toSet(), equals({waypointSymbol}));

        final exportBuys = await listings.whichBuysInSystem(
          system,
          exportSymbol,
        );
        // Exports don't count as buys.
        expect(exportBuys, isEmpty);
      });

      test('which exports', () async {
        final listings = db.marketListings;
        final system = waypointSymbol.system;

        await db.marketListings.upsert(marketListing);

        final exports = await listings.whichExportsInSystem(
          system,
          exportSymbol,
        );
        expect(exports.toSet(), equals({waypointSymbol}));

        // Imports don't count as exports.
        final imports = await listings.whichExportsInSystem(
          system,
          importSymbol,
        );
        expect(imports, isEmpty);
      });

      test('sells fuel', () async {
        await db.marketListings.upsert(marketListing);
        expect(await db.marketListings.sellsFuel(waypointSymbol), isFalse);

        final fuelWaypoint = WaypointSymbol.fromString('X1-B-1');
        final marketListingWithFuel = MarketListing(
          waypointSymbol: fuelWaypoint,
          imports: const {TradeSymbol.FUEL},
        );
        await db.marketListings.upsert(marketListingWithFuel);
        expect(await db.marketListings.sellsFuel(fuelWaypoint), isTrue);
        final unknown = WaypointSymbol.fromString('X1-C-1');
        expect(await db.marketListings.sellsFuel(unknown), isFalse);
      });

      test('snapshot', () async {
        await db.marketListings.upsert(marketListing);

        final listings = db.marketListings;
        final snapshot = await listings.snapshotAll();
        expect(snapshot.listings.length, equals(1));
        expect(snapshot.listings.first, equals(marketListing));

        final systemSnapshot = await listings.snapshotSystem(
          waypointSymbol.system,
        );
        expect(systemSnapshot.listings.length, equals(1));
        expect(systemSnapshot.listings.first, equals(marketListing));

        final otherSystem = SystemSymbol.fromString('X1-B');
        final otherSystemSnapshot = await listings.snapshotSystem(otherSystem);
        expect(otherSystemSnapshot.listings.length, equals(0));
      });

      test('markets which trade fuel', () async {
        final listings = db.marketListings;
        final fuelListing1 = MarketListing(
          waypointSymbol: WaypointSymbol.fromString('X1-A-1'),
          imports: const {TradeSymbol.FUEL},
        );
        final fuelListing2 = MarketListing(
          waypointSymbol: WaypointSymbol.fromString('X1-B-2'),
          exchange: const {TradeSymbol.FUEL},
        );
        final fuelListing3 = MarketListing(
          waypointSymbol: WaypointSymbol.fromString('X1-C-3'),
          exports: const {TradeSymbol.FUEL},
        );
        await listings.upsert(fuelListing1);
        await listings.upsert(fuelListing2);
        await listings.upsert(fuelListing3);
        final fuelMarkets = await listings.marketsSellingFuel();
        expect(fuelMarkets.length, equals(3));
      });
    });
  });
}
