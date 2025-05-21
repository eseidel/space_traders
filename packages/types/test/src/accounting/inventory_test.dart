import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('PricedInventory', () {
    test('round-trips through JSON', () {
      const inventory = PricedInventory(
        items: [
          PricedItemStack(
            tradeSymbol: TradeSymbol.IRON,
            count: 100,
            pricePerUnit: 50,
          ),
          PricedItemStack(
            tradeSymbol: TradeSymbol.COPPER,
            count: 200,
            pricePerUnit: 75,
          ),
        ],
      );

      // Convert to JSON
      final json = inventory.toJson();

      // Convert back from JSON
      final reconstructedInventory = PricedInventory.fromJson(json);
      expect(reconstructedInventory, equals(inventory));
    });

    test('handles items with null prices', () {
      const inventory = PricedInventory(
        items: [
          PricedItemStack(
            tradeSymbol: TradeSymbol.IRON,
            count: 100,
            pricePerUnit: null,
          ),
        ],
      );

      final json = inventory.toJson();
      final reconstructedInventory = PricedInventory.fromJson(json);

      expect(reconstructedInventory.items.length, equals(1));
      expect(reconstructedInventory.items[0].pricePerUnit, isNull);
      expect(reconstructedInventory.items[0].totalValue, isNull);
    });
  });

  group('PricedFleet', () {
    test('round-trips through JSON', () {
      const fleet = PricedFleet(
        ships: [
          PricedShip(shipType: ShipType.PROBE, count: 100, pricePerUnit: 50),
        ],
      );

      final json = fleet.toJson();
      final reconstructedFleet = PricedFleet.fromJson(json);
      expect(reconstructedFleet, equals(fleet));
    });
  });
}
