import 'dart:math';

import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/printing.dart';

/// What the max multiplier of median we would pay for a ship.
const maxMedianMultipler = 1.1;

/// This should probably wake up once an hour or so and then decide which
/// ship would be the best to buy with?
// Future<bool> shouldBuyShip(
//   Api api,
//   Agent agent,
//   WaypointCache waypointCache,
//   ShipyardPrices shipyardPrices,
//   Ship ship,
// ) async {
//   const shipType = ShipType.ORE_HOUND;
//   // Shipyard nearby that sells ships within 1.1x of the median price.
//   // We have enough money to buy the ship.

//   final shipyardWaypoints =
//       await waypointCache.shipyardWaypointsForSystem(ship.nav.systemSymbol);
//   if (shipyardWaypoints.isEmpty) {
//     return false;
//   }
//   final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
//   if (medianPrice == null) {
//     return false;
//   }
//   final maxPrice = medianPrice * 1.1;
//   if (agent.credits < maxPrice) {
//     return false;
//   }
//   for (final waypoint in shipyardWaypoints) {
//     final recentPrice = shipyardPrices.recentPurchasePrice(
//       shipyardSymbol: waypoint.symbol,
//       shipType: shipType,
//     );
//     // We could also assume it's median as a reason to explore?
//     if (recentPrice == null) {
//       continue;
//     }
//     if (recentPrice < maxPrice) {
//       return true;
//     }
//   }
//   return false;
// }

// TODO(eseidel): This only looks in the current system.
Future<Waypoint?> _nearbyShipyardWithBestPrice(
  WaypointCache waypointCache,
  ShipyardPrices shipyardPrices,
  Ship ship,
  ShipType shipType,
  double maxMedianMultipler,
) async {
  final shipyardWaypoints =
      await waypointCache.shipyardWaypointsForSystem(ship.nav.systemSymbol);
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
      shipyardSymbol: waypoint.symbol,
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

int _countOfTypeInFleet(ShipCache shipCache, ShipType shipType) {
  final frameForType = {
    ShipType.ORE_HOUND: ShipFrameSymbolEnum.MINER,
    ShipType.PROBE: ShipFrameSymbolEnum.PROBE,
    ShipType.LIGHT_HAULER: ShipFrameSymbolEnum.LIGHT_FREIGHTER,
  }[shipType];
  if (frameForType == null) {
    return 0;
  }
  return shipCache.frameCounts[frameForType] ?? 0;
}

// This is a hack for now, we need real planning.
ShipType? _shipTypeToBuy(ShipCache shipCache, {int? randomSeed}) {
  final isEarlyGame = shipCache.ships.length < 10;
  if (isEarlyGame) {
    return ShipType.ORE_HOUND;
  }

  final random = Random(randomSeed);
  final targetCounts = {
    ShipType.ORE_HOUND: 30,
    ShipType.PROBE: 10,
    ShipType.LIGHT_HAULER: 5,
  };
  final typesToBuy = targetCounts.keys
      .where(
        (shipType) =>
            _countOfTypeInFleet(shipCache, shipType) < targetCounts[shipType]!,
      )
      .toList();
  if (typesToBuy.isEmpty) {
    return null;
  }
  return typesToBuy[random.nextInt(typesToBuy.length)];
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
  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);

  final shipType = _shipTypeToBuy(caches.ships);
  if (shipType == null) {
    shipWarn(
      ship,
      'No ships needed, disabling behavior.',
    );
    await centralCommand.disableBehavior(ship, Behavior.buyShip);
    return null;
  }

  // Get our median price before updating shipyard prices.
  final medianPrice = caches.shipyardPrices.medianPurchasePrice(shipType);
  if (medianPrice == null) {
    shipWarn(
        ship,
        'Failed to buy ship, no median price for $shipType'
        'disabling behavior.');
    await centralCommand.disableBehavior(ship, Behavior.buyShip);
    return null;
  }
  final maxPrice = (medianPrice * maxMedianMultipler).toInt();
  final credits = caches.agent.agent.credits;
  if (credits < maxPrice) {
    shipWarn(
      ship,
      'Cant by $shipType, credits $credits < max price $maxPrice, '
      'disabling behavior.',
    );
    await centralCommand.disableBehavior(ship, Behavior.buyShip);
    return null;
  }

  // Assume we're at the right shipyard (could be wrong).
  if (currentWaypoint.hasShipyard) {
    // Update our shipyard prices regardless of any later errors.
    final shipyard = await getShipyard(api, currentWaypoint);
    await recordShipyardDataAndLog(caches.shipyardPrices, shipyard, ship);

    // We should *always* have a recent price, we just updated it.
    final recentPrice = caches.shipyardPrices.recentPurchasePrice(
      shipyardSymbol: currentWaypoint.symbol,
      shipType: shipType,
    )!;
    final recentPriceString = creditsString(recentPrice);
    if (recentPrice > maxPrice) {
      const timeout = Duration(minutes: 30);
      shipWarn(
        ship,
        'Failed to buy $shipType at ${currentWaypoint.symbol}, '
        '$recentPriceString > max price $maxPrice '
        'disabling behavior for ${approximateDuration(timeout)}.',
      );
      await centralCommand.disableBehavior(
        ship,
        Behavior.buyShip,
        timeout: timeout,
      );
      return null;
    }

    // Do we need to catch exceptions about insufficient credits?
    await purchaseShipAndLog(
      api,
      caches.marketPrices,
      caches.ships,
      caches.agent,
      ship,
      shipyard.symbol,
      shipType,
    );

    await centralCommand.completeBehavior(ship.symbol);
    await centralCommand.disableBehavior(
      ship,
      Behavior.buyShip,
      timeout: const Duration(minutes: 20),
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
    shipWarn(
        ship,
        'Failed to buy $shipType, no shipyard near ${ship.nav.waypointSymbol} '
        'with good price, disabling behavior.');
    await centralCommand.disableBehavior(ship, Behavior.buyShip);
    return null;
  }
  return beingRouteAndLog(
    api,
    ship,
    caches.systems,
    centralCommand,
    destination.symbol,
  );
}
