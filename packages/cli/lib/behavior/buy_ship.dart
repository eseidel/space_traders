import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';

/// Job to buy a ship.
// class ShipBuyJob {
//   /// Create a new ship buy job.
//   ShipBuyJob(this.shipType, this.waypointSymbol);

//   /// The type of ship to buy.
//   final ShipType shipType;

//   /// The waypoint to buy the ship at.
//   final String waypointSymbol;
// }

/// Called by CentralCommand.buyShipIfPossible.  Moved to this file
/// to try and share code.
Future<PurchaseShip201ResponseData> doBuyShipJob(
  Api api,
  ShipCache shipCache,
  ShipyardPrices shipyardPrices,
  AgentCache agentCache,
  TransactionLog transactionLog,
  Ship ship,
  WaypointSymbol shipyardSymbol,
  ShipType shipType, {
  required double maxMedianShipPriceMultipler,
  required int minimumCreditsForTrading,
}) async {
  // Get our median price before updating shipyard prices.
  final medianPrice = assertNotNull(
    shipyardPrices.medianPurchasePrice(shipType),
    'Failed to buy ship, no median price for $shipType.',
    const Duration(minutes: 10),
    disable: DisableBehavior.allShips,
  );
  final maxMedianMultiplier = maxMedianShipPriceMultipler;
  final maxPrice = medianPrice * maxMedianMultiplier;

  // We should only try to buy new ships if we have enough money to keep
  // our traders trading.
  final budget = agentCache.agent.credits - minimumCreditsForTrading;
  final credits = budget;
  jobAssert(
    credits >= maxPrice,
    'Can not buy $shipType, budget $credits < max price $maxPrice.',
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
    '$recentPriceString > max price $maxPrice.',
    const Duration(minutes: 10),
  );

  // Do we need to catch exceptions about insufficient credits?
  final result = await purchaseShipAndLog(
    api,
    shipCache,
    agentCache,
    transactionLog,
    ship,
    shipyardSymbol,
    shipType,
  );
  return result;
}

/// Apply the buy ship behavior.
Future<DateTime?> advanceBuyShip(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // final shipyardWaypoints =
  //     await caches.waypoints.shipyardWaypointsForSystem(ship.systemSymbol);
  // if (shipyardWaypoints.isEmpty) {
  //   centralCommand.disableBehaviorForShip(
  //     ship,
  //     Behavior.buyShip,
  //     'No shipyards in system ${ship.systemSymbol}.',
  //     const Duration(minutes: 10),
  //   );
  //   return null;
  // }

  // final shipyardWaypoint = shipyardWaypoints.first;
  // final shipyardSymbol = shipyardWaypoint.waypointSymbol;
  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyardWaypoint = hqWaypoints.firstWhere((w) => w.hasShipyard);
  final shipyardSymbol = shipyardWaypoint.waypointSymbol;

  final shipType = assertNotNull(
    centralCommand.shipTypeToBuy(
      ship,
      caches.shipyardPrices,
      caches.agent,
      shipyardSymbol,
    ),
    'No ship to buy at $shipyardSymbol.',
    const Duration(minutes: 10),
  );

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
    'Failed to buy $shipType at ${currentWaypoint.symbol}, '
    '$recentPriceString > max price $maxPrice.',
    const Duration(minutes: 30),
  );

  // Do we need to catch exceptions about insufficient credits?
  final result = await purchaseShipAndLog(
    api,
    caches.ships,
    caches.agent,
    caches.transactions,
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
