import 'dart:math';

import 'package:cli/cli.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final marketPrices = await db.marketPrices.snapshotAll();
  final marketListings = await db.marketListings.snapshotAll();

  logger.info(
    'Loaded ${marketPrices.prices.length} prices from '
    '${marketPrices.waypointCount} waypoints.',
  );

  final listedSymbols = <TradeSymbol>{};
  for (final listing in marketListings.listings) {
    listedSymbols.addAll(listing.tradeSymbols);
  }

  final maxNameLength = TradeSymbol.values.fold(
    0,
    (m, t) => max(m, t.value.length),
  );

  final sortedSymbols = TradeSymbol.values.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final tradeSymbol in sortedSymbols) {
    final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol);
    final hasListing = listedSymbols.contains(tradeSymbol);
    final noPriceString = hasListing ? '?' : '';
    final priceString =
        (medianPrice == null ? noPriceString : creditsString(medianPrice))
            .padLeft(13);
    final name = tradeSymbol.value;
    logger.info('${name.padRight(maxNameLength)} $priceString');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
