import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final marketPrices = MarketPrices.load(fs);

  logger.info(
    'Loaded ${marketPrices.count} prices from '
    '${marketPrices.waypointCount} waypoints.',
  );

  final maxNameLength =
      TradeSymbol.values.fold(0, (m, t) => max(m, t.value.length));

  for (final tradeSymbol in TradeSymbol.values) {
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