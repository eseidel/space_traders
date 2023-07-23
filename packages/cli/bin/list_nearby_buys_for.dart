import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';

class CostedTrip {
  CostedTrip({
    required this.route,
    required this.price,
  });
  final RoutePlan route;
  final MarketPrice price;
}

CostedTrip costTrip(
  Ship ship,
  RoutePlanner planner,
  MarketPrice price,
  WaypointSymbol start,
  WaypointSymbol end,
) {
  final route = planner.planRoute(
    start: start,
    end: end,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  return CostedTrip(
    route: route!,
    price: price,
  );
}

Future<void> command(FileSystem fs, List<String> args) async {
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final agentCache = AgentCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final shipCache = ShipCache.loadCached(fs)!;
  final ship = shipCache.ships.first;

  final hq = agentCache.headquartersSymbol;
  final start = hq;

  final prices = marketPrices.pricesFor(tradeSymbol).toList();

  final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = medianOrBelow.map(
    (price) => costTrip(ship, routePlanner, price, start, price.waypointSymbol),
  );

  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));

  for (final trip in sorted) {
    logger
        .info('${trip.route.duration} seconds for ${trip.price.purchasePrice}');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
