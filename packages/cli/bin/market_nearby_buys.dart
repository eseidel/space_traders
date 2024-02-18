import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = await MarketPrices.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: (_) => false,
  );
  final shipCache = ShipCache.load(fs)!;

  final ship = shipCache.ships.first;
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

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
