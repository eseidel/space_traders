import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

class ItemValue {
  ItemValue({
    required this.tradeSymbol,
    required this.count,
    required this.medianPrice,
  });

  final TradeSymbol tradeSymbol;
  final int count;
  final int? medianPrice;
}

class Inventory {
  Inventory({required this.items});

  Set<TradeSymbol> get missingPrices {
    return items
        .where((item) => item.medianPrice == null)
        .map((item) => item.tradeSymbol)
        .toSet();
  }

  int get totalValue {
    return items.fold(0, (total, item) {
      final price = item.medianPrice;
      if (price == null) {
        return total;
      }
      return total + (item.count * price);
    });
  }

  final List<ItemValue> items;
}

Future<Inventory> computeInventoryValue({required Database db}) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final countByTradeSymbol = <TradeSymbol, int>{};
  for (final ship in ships.ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.tradeSymbol;
      final count = countByTradeSymbol[symbol] ?? 0;
      countByTradeSymbol[symbol] = count + item.units;
    }
  }
  final items = countByTradeSymbol.entries.map((entry) {
    final symbol = entry.key;
    final count = entry.value;
    return ItemValue(
      tradeSymbol: symbol,
      count: count,
      medianPrice: marketPrices.medianSellPrice(symbol),
    );
  });
  return Inventory(items: items.toList());
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final inventory = await computeInventoryValue(db: db);
  for (final item in inventory.items) {
    final price = item.medianPrice;
    final count = item.count;
    final symbol = item.tradeSymbol;
    if (price == null) {
      logger.warn('No price for $symbol');
      continue;
    }
    final value = price * count;
    logger.info(
      '${symbol.value.padRight(23)} ${count.toString().padLeft(3)} x '
      '${creditsString(price).padRight(8)} = ${creditsString(value)}',
    );
  }
  logger.info('Total value: ${creditsString(inventory.totalValue)}');
}
