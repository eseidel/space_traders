import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';

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

CostedTrip findBestDealFor(
  MarketPrices marketPrices,
  RoutePlanner routePlanner,
  Ship ship,
  TradeSymbol tradeSymbol,
) {
  final prices = marketPrices.pricesFor(tradeSymbol).toList();
  final start = ship.waypointSymbol;

  // If there are a lot f prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = prices.map(
    (price) => costTrip(ship, routePlanner, price, start, price.waypointSymbol),
  );
  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));

  final nearest = sorted.first;
  // logger.info(
  //   'Nearest ${approximateDuration(nearest.route.duration)} '
  //   'for ${nearest.price.purchasePrice}',
  // );

  // Have a set time value of money (e.g. 7c/s)
  const expectedCreditsPerSecond = 7;

  var best = nearest;
  // Pick any one further that saves more than 7c/s
  for (final trip in sorted.sublist(1)) {
    final priceDiff = trip.price.purchasePrice - nearest.price.purchasePrice;
    final savings = -priceDiff;
    final extraTime = trip.route.duration - nearest.route.duration;
    final savingsPerSecond = savings / extraTime.inSeconds;
    if (savingsPerSecond > expectedCreditsPerSecond) {
      best = trip;
      break;
    }
  }

//   for (final trip in sorted.sublist(1)) {
//     logger.info(
//       '${approximateDuration(trip.route.duration)} '
//       'for ${trip.price.purchasePrice}',
//     );
//   }

  return best;
}

Future<void> command(FileSystem fs, List<String> args) async {
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
  final shipCache = ShipCache.loadCached(fs)!;

  final ship = shipCache.ships.first;
  const tradeSymbol = TradeSymbol.MOUNT_SURVEYOR_II;

  final best = findBestDealFor(
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
