import 'package:cli/cli.dart';
import 'package:cli/plan/trading.dart';

Future<void> command(Database db, ArgResults argResults) async {
  final marketPrices = await db.marketPrices.snapshotAll();
  final systemsCache = await db.systems.snapshotAllSystems();
  final routePlanner = await defaultRoutePlanner(db);
  final ships = await ShipSnapshot.load(db);

  const tradeSymbol = TradeSymbol.DIAMONDS;

  final hqSystem = await myHqSystemSymbol(db);
  final hqMine =
      systemsCache
          .waypointsInSystem(hqSystem)
          .firstWhere((w) => w.isAsteroid)
          .symbol;

  final miner = ships.ships.firstWhere((s) => s.isMiner);
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
    shipSpec: ship.shipSpec,
  );
  final supplyWidth = SupplyLevel.values.fold(0, (max, e) {
    final width = e.toString().length;
    return width > max ? width : max;
  });
  logger.info('Waypoint       Sell Supply    Volume   Round trip');
  for (final trip in trips) {
    final price = trip.price;
    logger.info(
      '${price.waypointSymbol.waypoint.padRight(14)} '
      // sellPrice is the price we sell *to* the market.
      '${creditsString(price.sellPrice).padLeft(4)} '
      '${price.supply.toString().padRight(supplyWidth)} '
      '${price.tradeVolume.toString().padLeft(6)} '
      '${approximateDuration(trip.route.duration * 2).padLeft(4)}',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
