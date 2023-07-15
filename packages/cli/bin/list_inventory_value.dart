import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> main(List<String> args) async {
  await runOffline(args, command);
}

Future<void> command(FileSystem fs, List<String> args) async {
  final shipCache = ShipCache.loadCached(fs)!;
  final marketPrices = MarketPrices.load(fs);
  final countByTradeSymbol = <String, int>{};
  final ships = shipCache.ships;
  for (final ship in ships) {
    final inventory = ship.cargo.inventory;
    for (final item in inventory) {
      final symbol = item.symbol;
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
        '${symbol.padRight(23)} ${count.toString().padLeft(3)} x '
        '${creditsString(price).padRight(8)} = ${creditsString(value)}',
      );
      return total + value;
    },
  );
  logger.info('Total value: ${creditsString(totalValue)}');
}
