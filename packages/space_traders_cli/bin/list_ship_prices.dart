import 'dart:math';

import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/shipyard_prices.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final shipyardPrices = await ShipyardPrices.load(fs);

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
