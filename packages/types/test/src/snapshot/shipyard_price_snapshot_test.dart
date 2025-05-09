import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('ShipyardPriceSnapshot', () {
    test('constructor', () {
      final snapshot = ShipyardPriceSnapshot([]);
      expect(snapshot.prices, isEmpty);
    });

    test('medianPurchasePrice', () {
      const shipType = ShipType.PROBE;
      ShipyardPrice makePrice(String waypoint, int price) {
        return ShipyardPrice(
          waypointSymbol: WaypointSymbol.fromString(waypoint),
          shipType: shipType,
          purchasePrice: price,
          timestamp: DateTime(2021),
        );
      }

      final expectedPrices = [
        makePrice('A-B-C', 100),
        makePrice('A-B-D', 200),
        makePrice('A-B-E', 300),
        makePrice('A-B-F', 400),
        makePrice('A-B-G', 500),
      ];
      final snapshot = ShipyardPriceSnapshot(expectedPrices);
      expect(snapshot.medianPurchasePrice(shipType), 300);

      final prices = snapshot.purchasePricesFor(shipType);
      expect(prices.length, 5);
      expect(prices.map((p) => p.purchasePrice).toSet(), {
        100,
        200,
        300,
        400,
        500,
      });

      expect(
        snapshot.recentPurchasePrice(
          shipyardSymbol: WaypointSymbol.fromString('A-B-C'),
          shipType: shipType,
        ),
        100,
      );
    });
  });
}
