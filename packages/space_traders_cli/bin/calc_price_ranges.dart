import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:stats/stats.dart';

void printPriceRanges(List<MarketPrice> gameStats) {
  void printStats(String label, Iterable<int> values) {
    final stats = Stats.fromData(values);
    logger.info('$label: ${stats.withPrecision(3)}');
  }

  for (final tradeSymbol in TradeSymbol.values) {
    final trades =
        gameStats.where((p) => p.symbol == tradeSymbol.value).toList();
    if (trades.isEmpty) {
      continue;
    }
    printStats('$tradeSymbol purchase', trades.map((p) => p.purchasePrice));
    printStats('$tradeSymbol sell', trades.map((p) => p.sellPrice));
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final prices = await PriceData.load(fs);

  logger.info('${prices.count} prices loaded.');
  printPriceRanges(prices.prices);
}
