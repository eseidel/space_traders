import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final marketPrices = await MarketPriceSnapshot.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: (_) => false,
  );
  // TODO(eseidel): Just use hq and command ship spec.
  final ships = await ShipSnapshot.load(db);
  final ship = ships.ships.first;
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;

  final best = findBestMarketToBuy(
    marketPrices,
    routePlanner,
    tradeSymbol,
    expectedCreditsPerSecond: 7,
    start: ship.waypointSymbol,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (best == null) {
    logger.info('No market to buy $tradeSymbol');
  } else {
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
