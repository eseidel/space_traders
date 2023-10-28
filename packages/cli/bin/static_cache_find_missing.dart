import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final shipCache = ShipCache.loadCached(fs)!;
  final staticCaches = StaticCaches.load(fs);

  final ship = shipCache.ships.first;

  final missingSymbols = ShipMountSymbolEnum.values
      .where((s) => staticCaches.mounts[s] == null)
      .toList();
  for (final mountSymbol in missingSymbols) {
    final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
    final marketTrip = findBestMarketToBuy(
      marketPrices,
      routePlanner,
      ship,
      tradeSymbol,
      // We don't really care about the value of the "trade".
      expectedCreditsPerSecond: 7,
    );
    if (marketTrip == null) {
      print('No market for $tradeSymbol');
      continue;
    }
    print('$tradeSymbol in ${approximateDuration(marketTrip.route.duration)} '
        ' ${marketTrip.price.waypointSymbol}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
