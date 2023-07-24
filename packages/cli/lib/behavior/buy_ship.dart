import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';

/// Apply the buy ship behavior.
Future<DateTime?> advanceBuyShip(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  assert(!ship.isInTransit, 'Ship ${ship.symbol} is in transit');
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

  final shipType = centralCommand.shipTypeToBuy(
    ship,
    caches.shipyardPrices,
    caches.agent,
    shipyardSymbol,
  );
  if (shipType == null) {
    centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'No ships needed.',
      const Duration(hours: 1),
    );
    return null;
  }

  // Get our median price before updating shipyard prices.
  final medianPrice = caches.shipyardPrices.medianPurchasePrice(shipType);
  // TODO(eseidel): As written, this can never buy a ship immediately on spawn.
  // Since we won't have surveyed any shipyards yet.
  if (medianPrice == null) {
    centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Failed to buy ship, no median price for $shipType.',
      const Duration(minutes: 20),
    );
    return null;
  }
  // Separate out the number of credits needed to go check
  // Which should be ~5% above the last price we saw.
  // In the early game, we'll pay any price, since the max price should really
  // be based on the opportunity cost of the travel.  Our expected earnings
  // early are low.
  final shipyardPrice = caches.shipyardPrices.recentPurchasePrice(
    shipyardSymbol: shipyardSymbol,
    shipType: shipType,
  );
  if (shipyardPrice == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.buyShip,
      'Failed to buy ship, no recent price for $shipType at $shipyardSymbol.',
      const Duration(minutes: 20),
    );
    return null;
  }
  final maxPriceToCheck = (shipyardPrice * 1.05).toInt();
  final maxMedianMultipler = centralCommand.maxMedianShipPriceMultipler;
  final maxPrice = (medianPrice * maxMedianMultipler).toInt();
  final credits = caches.agent.agent.credits;
  if (credits < maxPriceToCheck) {
    centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Can not buy $shipType at $shipyardSymbol, '
      'credits $credits < max price $maxPrice.',
      const Duration(minutes: 10),
    );
    return null;
  }

  if (currentWaypoint.waypointSymbol != shipyardSymbol) {
    // We're not there, go to the shipyard to purchase.
    return beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      shipyardSymbol,
    );
  }
  // Otherwise we're at the shipyard we intended to be at.

  // Update our shipyard prices regardless of any later errors.
  final shipyard = await getShipyard(api, currentWaypoint);
  if (!shipyard.hasShipType(shipType)) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.buyShip,
      'Shipyard at ${currentWaypoint.symbol} does not sell $shipType.',
      const Duration(minutes: 30),
    );
    return null;
  }

  await recordShipyardDataAndLog(caches.shipyardPrices, shipyard, ship);

  // We should *always* have a recent price unless the shipyard doesn't
  // sell that type of ship.
  final recentPrice = caches.shipyardPrices.recentPurchasePrice(
    shipyardSymbol: currentWaypoint.waypointSymbol,
    shipType: shipType,
  )!;
  final recentPriceString = creditsString(recentPrice);
  if (recentPrice > maxPrice) {
    centralCommand.disableBehaviorForShip(
      ship,
      Behavior.buyShip,
      'Failed to buy $shipType at ${currentWaypoint.symbol}, '
      '$recentPriceString > max price $maxPrice.',
      const Duration(minutes: 30),
    );
    return null;
  }

  // Do we need to catch exceptions about insufficient credits?
  final result = await purchaseShipAndLog(
    api,
    caches.ships,
    caches.agent,
    ship,
    shipyard.waypointSymbol,
    shipType,
  );

  // Record our success!
  centralCommand
    ..completeBehavior(ship.shipSymbol)
    ..disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Purchased ${result.ship.symbol} ($shipType)!',
      const Duration(minutes: 10),
    );
  return null;
}
