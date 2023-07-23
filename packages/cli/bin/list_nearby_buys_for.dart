import 'package:cli/behavior/deliver.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';

Future<void> command(FileSystem fs, List<String> args) async {
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
  );
  logger.info(
    'Best value for $tradeSymbol is '
    '${approximateDuration(best.route.duration)} away '
    'for ${creditsString(best.price.purchasePrice)}'
    ' at ${best.price.waypointSymbol}'
    ' (${best.price.tradeVolume} at a time)',
  );
}

void main(List<String> args) async {
  await runOffline(args, command);
}
