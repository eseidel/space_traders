import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/shipyard_prices.dart';
import 'package:space_traders_cli/surveys.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

/// What ship type we're currently buying.
const shipType = ShipType.LIGHT_HAULER;

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

/// Apply the buy ship behavior.
Future<DateTime?> advanceBuyShip(
  Api api,
  DataStore db,
  PriceData priceData,
  ShipyardPrices shipyardPrices,
  Agent agent,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  TransactionLog transactionLog,
  BehaviorManager behaviorManager,
  SurveyData surveyData,
) async {
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    waypointCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);

  // Get our median price before updating shipyard prices.
  final medianPrice = shipyardPrices.medianPurchasePrice(shipType);
  if (medianPrice == null) {
    shipWarn(
        ship,
        'Failed to buy ship, no median price for $shipType'
        'disabling behavior.');
    await behaviorManager.disableBehavior(ship, Behavior.buyShip);
    return null;
  }
  final maxPrice = (medianPrice * maxMedianMultipler).toInt();
  if (agent.credits < maxPrice) {
    shipWarn(
      ship,
      'Cant by ship, credits ${agent.credits} < max price $maxPrice, '
      'disabling behavior.',
    );
    await behaviorManager.disableBehavior(ship, Behavior.buyShip);
    return null;
  }

  // Assume we're at the right shipyard (could be wrong).
  if (currentWaypoint.hasShipyard) {
    // Update our shipyard prices regardless of any later errors.
    final shipyard = await getShipyard(api, currentWaypoint);
    await recordShipyardDataAndLog(shipyardPrices, shipyard, ship);

    // We should *always* have a recent price, we just updated it.
    final recentPrice = shipyardPrices.recentPurchasePrice(
      shipyardSymbol: currentWaypoint.symbol,
      shipType: shipType,
    )!;
    final recentPriceString = creditsString(recentPrice);
    if (recentPrice > maxPrice) {
      shipWarn(
        ship,
        'Failed to buy ship, $recentPriceString > max price $maxPrice '
        'disabling behavior.',
      );
      await behaviorManager.disableBehavior(ship, Behavior.buyShip);
      return null;
    }
    // Do we need to catch exceptions about insufficient credits?
    await purchaseShipAndLog(
      api,
      priceData,
      ship,
      agent,
      shipyard.symbol,
      shipType,
    );

    await behaviorManager.completeBehavior(ship.symbol);
    return null;
  }

  /// Otherwise, assume this is our first time through this behavior.
  /// Go to the nearest shipyard (maybe with best price?)
  final destination = await _nearbyShipyardWithBestPrice(
    waypointCache,
    shipyardPrices,
    ship,
    shipType,
    maxMedianMultipler,
  );
  if (destination == null) {
    shipWarn(
        ship,
        'Failed to buy ship, no nearby shipyard with good price '
        'disabling behavior.');
    await behaviorManager.disableBehavior(ship, Behavior.buyShip);
    return null;
  }
  return beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    destination.symbol,
  );
}
