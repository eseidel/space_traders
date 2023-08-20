import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Job to buy a ship.
class ShipBuyJob {
  /// Create a new ship buy job.
  ShipBuyJob(this.shipType, this.shipyardSymbol);

  /// The type of ship to buy.
  final ShipType shipType;

  /// The waypoint to buy the ship at.
  final WaypointSymbol shipyardSymbol;
}

/// Calculated trip cost of going and buying something.
class CostedTrip {
  /// Create a new costed trip.
  CostedTrip({required this.route, required this.price});

  /// The route to get there.
  final RoutePlan route;

  /// The historical price for the item at a given market.
  final ShipyardPrice price;
}

/// Compute the cost of going to and buying from a specific MarketPrice record.
CostedTrip? costTrip(
  Ship ship,
  RoutePlanner planner,
  ShipyardPrice price,
  WaypointSymbol start,
  WaypointSymbol end,
) {
  final route = planner.planRoute(
    start: start,
    end: end,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (route == null) {
    return null;
  }
  return CostedTrip(route: route, price: price);
}

List<CostedTrip> _marketsTradingSortedByDistance(
  ShipyardPrices shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipType shipType,
) {
  final prices = shipyardPrices.pricesFor(shipType).toList();
  if (prices.isEmpty) {
    return [];
  }
  final start = ship.waypointSymbol;

  // If there are a lot of prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = <CostedTrip>[];
  for (final price in prices) {
    final end = price.waypointSymbol;
    final trip = costTrip(ship, routePlanner, price, start, end);
    if (trip != null) {
      costed.add(trip);
    } else {
      logger.warn('No route from $start to $end');
    }
  }

  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));
  return sorted;
}

/// Find the best market to buy a given item from.
/// expectedCreditsPerSecond is the time value of money (e.g. 7c/s)
/// used for evaluating the trade-off between "closest" vs. "cheapest".
CostedTrip? findBestShipyardToBuy(
  ShipyardPrices shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipType shipType, {
  required int expectedCreditsPerSecond,
}) {
  final sorted = _marketsTradingSortedByDistance(
    shipyardPrices,
    routePlanner,
    ship,
    shipType,
  );
  if (sorted.isEmpty) {
    return null;
  }
  final nearest = sorted.first;
  var best = nearest;
  // Pick any one further that saves more than expectedCreditsPerSecond
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

  return best;
}

/// Called by CentralCommand.buyShipIfPossible.  Moved to this file
/// to try and share code.
Future<PurchaseShip201ResponseData> doBuyShipJob(
  Api api,
  Database db,
  ShipCache shipCache,
  ShipyardPrices shipyardPrices,
  AgentCache agentCache,
  Ship ship,
  ShipBuyJob job, {
  required double maxMedianShipPriceMultipler,
  required int minimumCreditsForTrading,
}) async {
  final shipyardSymbol = job.shipyardSymbol;
  final shipType = job.shipType;
  // Get our median price before updating shipyard prices.
  final medianPrice = assertNotNull(
    shipyardPrices.medianPurchasePrice(shipType),
    'Failed to buy ship, no median price for $shipType.',
    const Duration(minutes: 10),
    disable: DisableBehavior.allShips,
  );
  final maxMedianMultiplier = maxMedianShipPriceMultipler;
  final maxPrice = (medianPrice * maxMedianMultiplier).round();

  // We should only try to buy new ships if we have enough money to keep
  // our traders trading.
  final budget = agentCache.agent.credits - minimumCreditsForTrading;
  final credits = budget;
  jobAssert(
    credits >= maxPrice,
    'Can not buy $shipType, budget ${creditsString(credits)} '
    '< max price ${creditsString(maxPrice)}.',
    const Duration(minutes: 10),
    disable: DisableBehavior.allShips,
  );

  final recentPrice = assertNotNull(
    shipyardPrices.recentPurchasePrice(
      shipyardSymbol: shipyardSymbol,
      shipType: shipType,
    ),
    'Shipyard at $shipyardSymbol does not sell $shipType.',
    const Duration(minutes: 10),
  );

  final recentPriceString = creditsString(recentPrice);
  jobAssert(
    recentPrice <= maxPrice,
    'Failed to buy $shipType at $shipyardSymbol, '
    '$recentPriceString > max price ${creditsString(maxPrice)}.',
    const Duration(minutes: 10),
  );

  // Do we need to catch exceptions about insufficient credits?
  final result = await purchaseShipAndLog(
    api,
    db,
    shipCache,
    agentCache,
    ship,
    shipyardSymbol,
    shipType,
  );
  return result;
}

Future<ShipBuyJob?> _getShipBuyJob(
  CentralCommand centralCommand,
  WaypointCache waypointCache,
  AgentCache agentCache,
  ShipyardPrices shipyardPrices,
  Ship ship,
) async {
  final hqSystem = agentCache.headquartersSymbol.systemSymbol;
  final hqWaypoints = await waypointCache.waypointsInSystem(hqSystem);
  // const wantedType = ShipType.HEAVY_FREIGHTER;
  // final trip = assertNotNull(
  //   findBestShipyardToBuy(
  //     caches.shipyardPrices,
  //     caches.routePlanner,
  //     ship,
  //     wantedType,
  //     expectedCreditsPerSecond: 7,
  //   ),
  //   'No shipyards found to buy $wantedType.',
  //   const Duration(minutes: 10),
  // );

  final shipyardWaypoint = hqWaypoints.firstWhere((w) => w.hasShipyard);
  final shipyardSymbol = shipyardWaypoint.waypointSymbol;
  // final shipyardSymbol = trip.price.waypointSymbol;
  final shipType = centralCommand.shipTypeToBuy(
    ship,
    shipyardPrices,
    agentCache,
    shipyardSymbol,
  );
  if (shipType == null) {
    return null;
  }

  return ShipBuyJob(shipType, shipyardSymbol);
}

/// Apply the buy ship behavior.
Future<DateTime?> advanceBuyShip(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  final job = assertNotNull(
    await _getShipBuyJob(
      centralCommand,
      caches.waypoints,
      caches.agent,
      caches.shipyardPrices,
      ship,
    ),
    'No ship buy job.',
    const Duration(minutes: 10),
  );
  final shipyardSymbol = job.shipyardSymbol;
  final shipType = job.shipType;

  // Get our median price before updating shipyard prices.
  // TODO(eseidel): As written, this can never buy a ship immediately on spawn.
  // Since we won't have surveyed any shipyards yet.
  // Should just remove medianPrice and work from opportunity cost instead
  // like findBestMarketToBuyFrom does.
  final medianPrice = assertNotNull(
    caches.shipyardPrices.medianPurchasePrice(shipType),
    'Failed to buy ship, no median price for $shipType.',
    const Duration(minutes: 20),
    disable: DisableBehavior.allShips,
  );

  // Separate out the number of credits needed to go check
  // Which should be ~5% above the last price we saw.
  // In the early game, we'll pay any price, since the max price should really
  // be based on the opportunity cost of the travel.  Our expected earnings
  // early are low.
  final shipyardPrice = assertNotNull(
    caches.shipyardPrices.recentPurchasePrice(
      shipyardSymbol: shipyardSymbol,
      shipType: shipType,
    ),
    'Failed to buy ship, no recent price for $shipType at $shipyardSymbol.',
    const Duration(minutes: 20),
  );
  const priceAdjustment = 1.05;
  final maxPriceToCheck = (shipyardPrice * priceAdjustment).toInt();
  final credits = caches.agent.agent.credits;
  jobAssert(
    credits >= maxPriceToCheck,
    'Can not buy $shipType at $shipyardSymbol, '
    'credits ${creditsString(credits)} < '
    '$priceAdjustment * price = ${creditsString(maxPriceToCheck)}.',
    const Duration(minutes: 10),
    disable: DisableBehavior.allShips,
  );

  if (currentWaypoint.waypointSymbol != shipyardSymbol) {
    // We're not there, go to the shipyard to purchase.
    return beingNewRouteAndLog(
      api,
      ship,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      shipyardSymbol,
    );
  }
  // Otherwise we're at the shipyard we intended to be at.

  // Update our shipyard prices regardless of any later errors.
  final shipyard = await getShipyard(api, currentWaypoint);
  jobAssert(
    shipyard.hasShipType(shipType),
    'Shipyard at ${currentWaypoint.symbol} does not sell $shipType.',
    const Duration(minutes: 30),
  );

  recordShipyardDataAndLog(caches.shipyardPrices, shipyard, ship);

  // We should *always* have a recent price unless the shipyard doesn't
  // sell that type of ship.
  final recentPrice = caches.shipyardPrices.recentPurchasePrice(
    shipyardSymbol: currentWaypoint.waypointSymbol,
    shipType: shipType,
  )!;
  final recentPriceString = creditsString(recentPrice);
  final maxMedianMultipler = centralCommand.maxMedianShipPriceMultipler;
  final maxPrice = (medianPrice * maxMedianMultipler).toInt();
  jobAssert(
    recentPrice <= maxPrice,
    'Failed to buy $shipType at $shipyardSymbol, '
    '$recentPriceString > max price ${creditsString(maxPrice)}.',
    const Duration(minutes: 10),
  );

  // Do we need to catch exceptions about insufficient credits?
  final result = await purchaseShipAndLog(
    api,
    db,
    caches.ships,
    caches.agent,
    ship,
    shipyard.waypointSymbol,
    shipType,
  );

  // Record our success!
  centralCommand.completeBehavior(ship.shipSymbol);
  jobAssert(
    false,
    'Purchased ${result.ship.symbol} ($shipType)!',
    const Duration(minutes: 10),
    disable: DisableBehavior.allShips,
  );
  return null;
}
