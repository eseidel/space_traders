import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final shipyardPrices = ShipyardPrices.load(fs);
  final shipyardShips = ShipyardShipCache.load(fs);
  final showAll = argResults['all'] as bool;

  logger.info(
    'Loaded ${shipyardPrices.count} prices from '
    '${shipyardPrices.waypointCount} waypoints.',
  );

  final table = Table(
    header: [
      'Type',
      'Price',
      'Cargo',
      'Fuel',
      'Speed',
      'Mount Points',
    ],
    style: const TableStyle(compact: true),
  );

  for (final shipType in ShipType.values) {
    final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
    if (medianPrice == null && !showAll) {
      continue;
    }
    final name = shipType.value.substring('SHIP_'.length);
    final ship = shipyardShips[shipType];
    table.add([
      name,
      if (medianPrice == null) '' else creditsString(medianPrice),
      ship?.cargoCapacity,
      ship?.frame.fuelCapacity,
      ship?.engine.speed,
      ship?.frame.mountingPoints,
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (parser) {
      parser.addFlag(
        'all',
        abbr: 'a',
        negatable: false,
        help:
            'Print all ship types, including those not available for purchase.',
      );
    },
  );
}
