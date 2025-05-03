import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  group('PricedInventory', () {
    test('round-trips through JSON', () {
      final inventory = PricedInventory(
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

      // Verify the reconstructed object matches the original
      expect(
        reconstructedInventory.items.length,
        equals(inventory.items.length),
      );

      for (var i = 0; i < inventory.items.length; i++) {
        final original = inventory.items[i];
        final reconstructed = reconstructedInventory.items[i];

        expect(reconstructed.tradeSymbol, equals(original.tradeSymbol));
        expect(reconstructed.count, equals(original.count));
        expect(reconstructed.pricePerUnit, equals(original.pricePerUnit));
      }
    });

    test('handles items with null prices', () {
      final inventory = PricedInventory(
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
}
