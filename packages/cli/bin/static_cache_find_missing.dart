import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final marketPrices = await MarketPriceSnapshot.load(db);
  final systemsCache = SystemsCache.load(fs)!;
  final systemConnectivity = await loadSystemConnectivity(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: (_) => false,
  );
  final ships = await ShipSnapshot.load(db);
  final staticCaches = StaticCaches.load(fs);

  final ship = ships.ships.first;

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
