import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/ships.dart';
import 'package:collection/collection.dart';

/// Compute the total value across all cargo for all ships.
Future<int> computeInventoryValue(
  ShipSnapshot ships,
  // TODO(eseidel): Use a MedianPriceCache rather than MarketPriceSnapshot.
  MarketPriceSnapshot marketPrices,
) async {
  final countByTradeSymbol = <TradeSymbol, int>{};
  for (final ship in ships.ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.tradeSymbol;
      final count = countByTradeSymbol[symbol] ?? 0;
      countByTradeSymbol[symbol] = count + item.units;
    }
  }
  final totalValue = countByTradeSymbol.entries.fold<int>(0, (total, entry) {
    final symbol = entry.key;
    final count = entry.value;
    final price = marketPrices.medianSellPrice(symbol);
    if (price == null) {
      logger.warn('No price for $symbol');
      return total;
    }
    final value = price * count;
    return total + value;
  });
  return totalValue;
}

/// Computes the total resale value of all ships.
Future<int> computeShipValue(
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

  final shipTypes = ships.ships.map(shipTypeForShip).toList();
  final totalShipCost =
      shipTypes.map((s) => shipyardPrices.medianPurchasePrice(s)!).sum;

  // TODO(eseidel): Include mount values.

  return totalShipCost;
}

/// Computes the current balance sheet for the agent.
Future<BalanceSheet> computeBalanceSheet(FileSystem fs, Database db) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final shipyardShips = ShipyardShipCache.load(fs);

  final agent = await db.getMyAgent();
  final inventory = await computeInventoryValue(ships, marketPrices);
  final shipsValue = await computeShipValue(
    ships,
    shipyardShips,
    shipyardPrices,
  );

  return BalanceSheet(
    time: DateTime.timestamp(),
    cash: agent!.credits,
    inventory: inventory,
    ships: shipsValue,
  );
}
