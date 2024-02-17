import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = MarketPrices.load(fs);
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

  const tradeSymbol = TradeSymbol.DIAMONDS;

  final hqSystem = await myHqSystemSymbol(db);
  final hqMine = systemsCache
      .waypointsInSystem(hqSystem)
      .firstWhere((w) => w.isAsteroid)
      .symbol;

  final miner = shipCache.ships.firstWhere((s) => s.isMiner);
  final ship = miner.deepCopy();
  ship.nav.waypointSymbol = hqMine.waypoint;
  ship.nav.systemSymbol = hqMine.systemString;
  logger.info('Finding markets which buy $tradeSymbol near $hqMine.');

  // List all markets nearby which buy diamonds.
  final trips = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: ship.waypointSymbol,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  final supplyWidth = SupplyLevel.values.fold(0, (max, e) {
    final width = e.toString().length;
    return width > max ? width : max;
  });
  logger.info('Waypoint       Sell Supply    Volume   Round trip');
  for (final trip in trips) {
    final price = trip.price;
    logger.info('${price.waypointSymbol.waypoint.padRight(14)} '
        // sellPrice is the price we sell *to* the market.
        '${creditsString(price.sellPrice).padLeft(4)} '
        '${price.supply.toString().padRight(supplyWidth)} '
        '${price.tradeVolume.toString().padLeft(6)} '
        '${approximateDuration(trip.route.duration * 2).padLeft(4)}');
  }
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
