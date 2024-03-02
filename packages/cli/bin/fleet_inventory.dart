import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final ships = await ShipSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.load(db);
  final countByTradeSymbol = <TradeSymbol, int>{};
  for (final ship in ships.ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.tradeSymbol;
      final count = countByTradeSymbol[symbol] ?? 0;
      countByTradeSymbol[symbol] = count + item.units;
    }
  }
  final totalValue = countByTradeSymbol.entries.fold<int>(
    0,
    (total, entry) {
      final symbol = entry.key;
      final count = entry.value;
      final price = marketPrices.medianSellPrice(symbol);
      if (price == null) {
        logger.warn('No price for $symbol');
        return total;
      }
      final value = price * count;
      logger.info(
        '${symbol.value.padRight(23)} ${count.toString().padLeft(3)} x '
        '${creditsString(price).padRight(8)} = ${creditsString(value)}',
      );
      return total + value;
    },
  );
  logger.info('Total value: ${creditsString(totalValue)}');
}
