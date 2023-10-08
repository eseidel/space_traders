import 'dart:math';

import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);

  logger.info(
    'Loaded ${marketPrices.count} prices from '
    '${marketPrices.waypointCount} waypoints.',
  );

  final maxNameLength =
      TradeSymbol.values.fold(0, (m, t) => max(m, t.value.length));

  final sortedSymbols = TradeSymbol.values.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final tradeSymbol in sortedSymbols) {
    final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol);
    final priceString =
        (medianPrice == null ? '' : creditsString(medianPrice)).padLeft(13);
    final name = tradeSymbol.value;
    logger.info('${name.padRight(maxNameLength)} $priceString');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
