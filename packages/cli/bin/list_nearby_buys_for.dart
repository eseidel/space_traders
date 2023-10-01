import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final shipCache = ShipCache.loadCached(fs)!;

  final ship = shipCache.ships.first;
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;

  final best = findBestMarketToBuy(
    marketPrices,
    routePlanner,
    ship,
    tradeSymbol,
    expectedCreditsPerSecond: 7,
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
