import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:types/types.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final agentCache = AgentCache.loadCached(fs)!;
  final shipCache = ShipCache.loadCached(fs)!;

  const tradeSymbol = TradeSymbol.DIAMONDS;

  final hq = agentCache.headquarters(systemsCache);
  final hqMine = systemsCache
      .waypointsInSystem(hq.systemSymbol)
      .firstWhere((w) => w.isAsteroidField)
      .waypointSymbol;

  final ship = shipCache.ships.firstWhere((s) => s.isMiner);

  // This hack is OK so long as we don't write the ShipCache to disk.
  ship.nav.waypointSymbol = hqMine.waypoint;
  ship.nav.systemSymbol = hqMine.system;
  logger.info('Finding markets which buy $tradeSymbol near $hqMine.');

  // List all markets nearby which buy diamonds.
  final trips = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    ship,
    tradeSymbol,
  );
  final supplyWidth = MarketTradeGoodSupplyEnum.values.fold(0, (max, e) {
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
