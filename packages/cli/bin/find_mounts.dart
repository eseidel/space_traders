import 'package:cli/cli.dart';
import 'package:cli/plan/trading.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final routePlanner = await defaultRoutePlanner(db);
  // TODO(eseidel): Just use hq and command ship spec.
  final ships = await ShipSnapshot.load(db);
  final ship = ships.ships.first;

  final mounts = [
    TradeSymbol.MOUNT_SURVEYOR_I,
    TradeSymbol.MOUNT_SURVEYOR_II,
    TradeSymbol.MOUNT_MINING_LASER_I,
    TradeSymbol.MOUNT_MINING_LASER_II,
  ];

  for (final tradeSymbol in mounts) {
    final best = findBestMarketToBuy(
      marketPrices,
      routePlanner,
      tradeSymbol,
      expectedCreditsPerSecond: 7,
      start: ship.waypointSymbol,
      shipSpec: ship.shipSpec,
    );
    if (best == null) {
      logger.info('No market to buy $tradeSymbol');
      continue;
    }
    logger.info(
      'Best value for $tradeSymbol is '
      '${approximateDuration(best.route.duration)} away '
      'for ${creditsString(best.price.purchasePrice)}'
      ' at ${best.price.waypointSymbol}'
      ' (${best.price.tradeVolume} at a time)',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
