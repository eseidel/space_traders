import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('MarketListingSnapshot', () {
    test('whichExportsInSystem', () {
      const tradeSymbol = TradeSymbol.DIAMONDS;
      final waypointSymbol = WaypointSymbol.fromString('A-B-C');
      final marketListing = MarketListing(
        waypointSymbol: waypointSymbol,
        exports: const {tradeSymbol},
      );
      final marketListingSnapshot = MarketListingSnapshot([marketListing]);
      final result = marketListingSnapshot.whichExportsInSystem(
        waypointSymbol.system,
        tradeSymbol,
      );
      expect(result, isNotEmpty);
    });

    test('countInSystem', () {
      const tradeSymbol = TradeSymbol.DIAMONDS;
      final waypointSymbol = WaypointSymbol.fromString('A-B-C');
      final marketListing = MarketListing(
        waypointSymbol: waypointSymbol,
        exports: const {tradeSymbol},
      );
      final marketListingSnapshot = MarketListingSnapshot([marketListing]);
      final result = marketListingSnapshot.countInSystem(waypointSymbol.system);
      expect(result, 1);
    });

    test('knowOfMarketWhichTrades', () {
      const tradeSymbol = TradeSymbol.DIAMONDS;
      final waypointSymbol = WaypointSymbol.fromString('A-B-C');
      final marketListing = MarketListing(
        waypointSymbol: waypointSymbol,
        exports: const {tradeSymbol},
      );
      final marketListingSnapshot = MarketListingSnapshot([marketListing]);
      final result = marketListingSnapshot.knowOfMarketWhichTrades(tradeSymbol);
      expect(result, isTrue);
    });

    test('systemsWithAtLeastNMarkets', () {
      const tradeSymbol = TradeSymbol.DIAMONDS;
      final marketListings = [
        MarketListing(
          waypointSymbol: WaypointSymbol.fromString('A-A-C'),
          exports: const {tradeSymbol},
        ),
        MarketListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-D'),
          exports: const {tradeSymbol},
        ),
        MarketListing(
          waypointSymbol: WaypointSymbol.fromString('A-B-E'),
          exports: const {tradeSymbol},
        ),
      ];
      final marketListingSnapshot = MarketListingSnapshot(marketListings);
      final result = marketListingSnapshot.systemsWithAtLeastNMarkets(2);
      expect(result, equals([SystemSymbol.fromString('A-B')]));
    });
  });
}
