import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';

// TODO(eseidel): This only looks in the current system.
Future<Waypoint?> _nearbyShipyardWithBestPrice(
  WaypointCache waypointCache,
  ShipyardPrices shipyardPrices,
  Ship ship,
  ShipType shipType,
  double maxMedianMultipler,
) async {
  final shipyardWaypoints =
      await waypointCache.shipyardWaypointsForSystem(ship.systemSymbol);
  if (shipyardWaypoints.isEmpty) {
    return null;
  }
  final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
  if (medianPrice == null) {
    return null;
  }
  Waypoint? bestWaypoint;
  int? bestPrice;
  for (final waypoint in shipyardWaypoints) {
    final recentPrice = shipyardPrices.recentPurchasePrice(
      shipyardSymbol: waypoint.waypointSymbol,
      shipType: shipType,
    );
    // We could also assume it's median as a reason to explore?
    if (recentPrice == null) {
      continue;
    }
    if (bestPrice == null || recentPrice < bestPrice) {
      bestPrice = recentPrice;
      bestWaypoint = waypoint;
    }
  }
  if (bestPrice != null && bestPrice > medianPrice * maxMedianMultipler) {
    return null;
  }
  return bestWaypoint;
}

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

  final shipType = centralCommand.shipTypeToBuy(
    ship,
    caches.shipyardPrices,
    caches.agent,
  );
  if (shipType == null) {
    await centralCommand.disableBehaviorForAll(
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
    await centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Failed to buy ship, no median price for $shipType.',
      const Duration(minutes: 30),
    );
    return null;
  }
  final maxMedianMultipler = centralCommand.maxMedianShipPriceMultipler;
  final maxPrice = (medianPrice * maxMedianMultipler).toInt();
  final credits = caches.agent.agent.credits;
  if (credits < maxPrice) {
    await centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Can not buy $shipType, credits $credits < max price $maxPrice.',
      const Duration(minutes: 20),
    );
    return null;
  }

  // Assume we're at the right shipyard (could be wrong).
  if (currentWaypoint.hasShipyard) {
    // Update our shipyard prices regardless of any later errors.
    final shipyard = await getShipyard(api, currentWaypoint);
    if (!shipyard.hasShipType(shipType)) {
      await centralCommand.disableBehaviorForShip(
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
      await centralCommand.disableBehaviorForShip(
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

    await centralCommand.completeBehavior(ship.symbol);
    await centralCommand.disableBehaviorForAll(
      ship,
      Behavior.buyShip,
      'Purchased ${result.ship.symbol} ($shipType)!',
      const Duration(minutes: 10),
    );
    return null;
  }

  /// Otherwise, assume this is our first time through this behavior.
  /// Go to the nearest shipyard (maybe with best price?)
  final destination = await _nearbyShipyardWithBestPrice(
    caches.waypoints,
    caches.shipyardPrices,
    ship,
    shipType,
    maxMedianMultipler,
  );
  if (destination == null) {
    const timeout = Duration(minutes: 30);
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.buyShip,
      'No shipyard near ${ship.waypointSymbol} '
      'with good price for $shipType.',
      timeout,
    );
    return null;
  }
  return beingNewRouteAndLog(
    api,
    ship,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    destination.waypointSymbol,
  );
}
