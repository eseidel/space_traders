import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';

/// Counts the number of occurrences of each element in the iterable.
extension CountBy<T> on Iterable<T> {
  /// Counts the number of occurrences of each element in the iterable.
  Map<K, int> countBy<K>(K Function(T element) keyOf) {
    final counts = <K, int>{};
    for (final item in this) {
      final key = keyOf(item);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }
}

/// Computes the total resale value of all items in the inventory.
Future<PricedInventory> computeInventoryValue({required Database db}) async {
  final ships = await ShipSnapshot.load(db);
  // TODO(eseidel): Use a MedianPriceCache rather than MarketPriceSnapshot.
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final countByTradeSymbol = ships.ships
      .expand((ship) => ship.cargo.inventory)
      .countBy((item) => item.tradeSymbol);

  final items =
      countByTradeSymbol.entries.map((entry) {
        final symbol = entry.key;
        final count = entry.value;
        return PricedItemStack(
          tradeSymbol: symbol,
          count: count,
          pricePerUnit: marketPrices.medianSellPrice(symbol),
        );
      }).toList();
  return PricedInventory(items: items);
}

/// Computes the total resale value of all ships.
Future<PricedFleet> computeShipValue(
  ShipSnapshot ships,
  ShipyardShipCache shipyardShips,
  ShipyardPriceSnapshot shipyardPrices,
) async {
  ShipType shipTypeForShip(Ship ship) {
    final type = guessShipType(shipyardShips, ship);
    if (type == null) {
      throw StateError('Unknown ship type for frame: ${ship.frame.symbol}');
    }
    return type;
  }

  final pricedShips =
      ships.ships.countBy(shipTypeForShip).entries.map((entry) {
        final symbol = entry.key;
        final count = entry.value;
        return PricedShip(
          shipType: symbol,
          count: count,
          // Note this is using purchase price rather than scrap price
          // which is likely over-estimating the value.
          pricePerUnit: shipyardPrices.medianPurchasePrice(symbol),
        );
      }).toList();

  return PricedFleet(ships: pricedShips);
}

/// Computes the current balance sheet for the agent.
Future<BalanceSheet> computeBalanceSheet(FileSystem fs, Database db) async {
  final ships = await ShipSnapshot.load(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);

  final agent = await db.getMyAgent();
  final inventory = await computeInventoryValue(db: db);
  for (final symbol in inventory.missingPrices) {
    logger.warn('Missing price for $symbol');
  }

  final shipsValue = await computeShipValue(
    ships,
    shipyardShips,
    shipyardPrices,
  );

  return BalanceSheet(
    time: DateTime.timestamp(),
    cash: agent!.credits,
    inventory: inventory.totalValue,
    ships: shipsValue.totalValue,
  );
}
