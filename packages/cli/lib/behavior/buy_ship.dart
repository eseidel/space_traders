import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
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

/// CostedTrip for ShipyardPrice.
typedef ShipyardTrip = CostedTrip<ShipyardPrice>;

List<ShipyardTrip> _shipyardsSellingByDistance(
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

  final costed = <ShipyardTrip>[];
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
ShipyardTrip? findBestShipyardToBuy(
  ShipyardPrices shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipType shipType, {
  required int expectedCreditsPerSecond,
}) {
  final sorted = _shipyardsSellingByDistance(
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

Future<ShipBuyJob?> _buySpecificShip(
  ShipyardPrices shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
  ShipCache shipCache,
  BehaviorCache behaviorCache,
  AgentCache agentCache,
  ShipType wantedType,
) async {
  final trip = assertNotNull(
    findBestShipyardToBuy(
      shipyardPrices,
      routePlanner,
      ship,
      wantedType,
      expectedCreditsPerSecond: 7,
    ),
    'No shipyards found to buy $wantedType.',
    const Duration(minutes: 10),
  );

  // final shipyardWaypoint = hqWaypoints.firstWhere((w) => w.hasShipyard);
  // final shipyardSymbol = shipyardWaypoint.waypointSymbol;
  final shipyardSymbol = trip.price.waypointSymbol;
  final shipType = _shipTypeToBuy(
    behaviorCache,
    shipCache,
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

ShipType? _shipTypeToBuy(
  BehaviorCache behaviorCache,
  ShipCache shipCache,
  Ship ship,
  ShipyardPrices shipyardPrices,
  AgentCache agentCache,
  WaypointSymbol shipyardSymbol,
) {
  // We should buy a new ship when:
  // - We have request capacity to spare
  // - We have money to spare.
  // - We don't have better uses for the money (e.g. trading or modules)

  bool shipyardHas(ShipType shipType) {
    return shipyardPrices.recentPurchasePrice(
          shipyardSymbol: shipyardSymbol,
          shipType: shipType,
        ) !=
        null;
  }

  // Buy ships based on earnings of that ship type over the last N hours?
  final systemSymbol = ship.systemSymbol;
  final hqSystemSymbol = agentCache.headquartersSymbol.systemSymbol;
  final inStartSystem = systemSymbol == hqSystemSymbol;

  // Early game can stop when we have enough miners going and markets
  // mapped to start trading.
  // This is not enough:
  // Loaded 364 prices from 61 markets and 7 prices from 2 shipyards.
  // Probably need a couple hundred markets.

  final targetCounts = {
    ShipType.ORE_HOUND: 90,
    // ShipType.PROBE: 0,
    // ShipType.LIGHT_HAULER: 0,
    ShipType.HEAVY_FREIGHTER: 5,
  };
  final typesToBuy = targetCounts.keys.where((shipType) {
    if (!shipyardHas(shipType)) {
      logger.info("Shipyard doesn't have $shipType");
      return false;
    }
    return shipCache.countOfType(shipType) < targetCounts[shipType]!;
  }).toList();
  logger.info('typesToBuy: $typesToBuy');
  if (typesToBuy.isEmpty) {
    return null;
  }

  final idleHaulers = idleHaulerSymbols(shipCache, behaviorCache);
  logger.info('${idleHaulers.length} idle haulers');
  final buyTraders = idleHaulers.length < 2;

  // We should buy ore-hounds only if we're at a system which has good mining.
  if (typesToBuy.contains(ShipType.ORE_HOUND) && inStartSystem) {
    return ShipType.ORE_HOUND;
  }
  // // We should buy probes if we have fewer than X of them.  We need probes
  // // first to explore before traders are useful.
  // if (typesToBuy.contains(ShipType.PROBE)) {
  //   return ShipType.PROBE;
  // }
  // // We should buy haulers if we have fewer than X haulers idle and we have
  // // enough extra cash on hand to support trading.
  // if (typesToBuy.contains(ShipType.LIGHT_HAULER) && buyTraders) {
  //   return ShipType.LIGHT_HAULER;
  // }
  // Heavy traders are the last option after other types have been filled?
  if (typesToBuy.contains(ShipType.HEAVY_FREIGHTER) && buyTraders) {
    return ShipType.HEAVY_FREIGHTER;
  }
  return null;
}

Future<ShipBuyJob?> _getShipBuyJob(
  ShipCache shipCache,
  BehaviorCache behaviorCache,
  WaypointCache waypointCache,
  AgentCache agentCache,
  ShipyardPrices shipyardPrices,
  RoutePlanner routePlanner,
  Ship ship,
) async {
  // final hqSystem = agentCache.headquartersSymbol.systemSymbol;
  // final hqWaypoints = await waypointCache.waypointsInSystem(hqSystem);
  return _buySpecificShip(
    shipyardPrices,
    routePlanner,
    ship,
    shipCache,
    behaviorCache,
    agentCache,
    ShipType.HEAVY_FREIGHTER,
  );
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
      caches.ships,
      caches.behaviors,
      caches.waypoints,
      caches.agent,
      caches.shipyardPrices,
      caches.routePlanner,
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
  );

  if (currentWaypoint.waypointSymbol != shipyardSymbol) {
    // We're not there, go to the shipyard to purchase.
    return beingNewRouteAndLog(
      api,
      ship,
      state,
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
  state.isComplete = true;
  jobAssert(
    false,
    'Purchased ${result.ship.symbol} ($shipType)!',
    const Duration(minutes: 10),
  );
  return null;
}
