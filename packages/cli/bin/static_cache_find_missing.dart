import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateCache = JumpGateCache.load(fs);
  final routePlanner = RoutePlanner.fromCaches(
    systemsCache,
    jumpGateCache,
    sellsFuel: (_) => false,
  );
  final shipCache = ShipCache.load(fs)!;
  final staticCaches = StaticCaches.load(fs);

  final ship = shipCache.ships.first;

  final missingSymbols = ShipMountSymbolEnum.values
      .where((s) => staticCaches.mounts[s] == null)
      .toList();
  final trips = <MarketTrip>[];
  for (final mountSymbol in missingSymbols) {
    final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
    final marketTrip = findBestMarketToBuy(
      marketPrices,
      routePlanner,
      tradeSymbol,
      // We don't really care about the value of the "trade".
      expectedCreditsPerSecond: 7,
      start: ship.waypointSymbol,
      fuelCapacity: ship.fuel.capacity,
      shipSpeed: ship.engine.speed,
    );
    if (marketTrip == null) {
      logger.info('No market for $tradeSymbol');
    } else {
      trips.add(marketTrip);
    }
  }
  trips.sortBy((trip) => trip.route.duration);
  for (final trip in trips) {
    logger.info(
      '${trip.price.tradeSymbol} in '
      '${approximateDuration(trip.route.duration)}',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
