import 'package:cli/cache/shipyard_listing_cache.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final showAll = argResults['all'] as bool;

  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  logger.info(
    'Loaded ${shipyardPrices.count} prices from '
    '${shipyardPrices.waypointCount} waypoints.',
  );
  final shipyardListings = await ShipyardListingSnapshot.load(db);
  logger.info(
    'Loaded ${shipyardListings.count} listings from '
    '${shipyardListings.waypointCount} waypoints.',
  );
  final shipyardShips = ShipyardShipCache.load(fs);

  final table = Table(
    header: [
      'Type',
      '# Loc',
      'Med. Price',
      'Cargo',
      'Fuel',
      'Speed',
      'Mounts',
    ],
    style: const TableStyle(compact: true),
  );

  Map<String, dynamic> r(Object? content) => <String, dynamic>{
        'content': content.toString(),
        'hAlign': HorizontalAlign.right,
      };

  for (final shipType in ShipType.values) {
    final listings = shipyardListings.listingsWithShip(shipType);
    if (!showAll && listings.isEmpty) {
      continue;
    }
    final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
    final name = shipType.value.substring('SHIP_'.length);
    final ship = shipyardShips[shipType];
    table.add([
      name,
      r(listings.length),
      if (medianPrice == null) '' else r(creditsString(medianPrice)),
      r(ship?.cargoCapacity),
      r(ship?.frame.fuelCapacity),
      r(ship?.engine.speed),
      r(ship?.frame.mountingPoints),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (ArgParser parser) {
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
