import 'dart:math';

import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipyardPrices = ShipyardPrices.load(fs);

  logger.info(
    'Loaded ${shipyardPrices.count} prices from '
    '${shipyardPrices.waypointCount} waypoints.',
  );

  final maxNameLength =
      ShipType.values.fold(0, (m, t) => max(m, t.value.length));

  // Load up the ShipyardPrices.
  // Walk through all ship types.
  // Print median price for each.
  for (final shipType in ShipType.values) {
    final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
    final priceString =
        (medianPrice == null ? '' : creditsString(medianPrice)).padLeft(13);
    final name = shipType.value.substring('SHIP_'.length);
    logger.info('${name.padRight(maxNameLength)} $priceString');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
