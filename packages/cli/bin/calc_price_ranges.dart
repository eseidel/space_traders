import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:file/local.dart';
import 'package:stats/stats.dart';

void printPriceRanges(List<MarketPrice> gameStats) {
  void printStats(String label, Iterable<int> values) {
    final stats = Stats.fromData(values);
    logger.info('$label: ${stats.withPrecision(3)}');
  }

  for (final tradeSymbol in TradeSymbol.values) {
    final trades = gameStats.where((p) => p.symbol == tradeSymbol).toList();
    if (trades.isEmpty) {
      continue;
    }
    printStats('$tradeSymbol purchase', trades.map((p) => p.purchasePrice));
    printStats('$tradeSymbol sell', trades.map((p) => p.sellPrice));
  }
}

Future<void> command(FileSystem fs, List<String> args) async {
  const fs = LocalFileSystem();
  final prices = MarketPrices.load(fs);

  logger.info('${prices.count} prices loaded.');
  printPriceRanges(prices.prices);
}

void main(List<String> args) {
  runOffline(args, command);
}
