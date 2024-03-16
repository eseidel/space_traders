import 'package:cli/behavior/job.dart';
import 'package:cli/behavior/jobs/buy_job.dart';
import 'package:cli/behavior/jobs/mount_job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Compute the nearest shipyard to the given start.
Future<ShipyardListing?> nearestShipyard(
  RoutePlanner routePlanner,
  ShipyardListingSnapshot shipyards,
  WaypointSymbol start,
) async {
  final listings = shipyards.listingsInSystem(start.system);
  // TODO(eseidel): Sort by distance.
  // TODO(eseidel): Consider reachable systems not just this one.
  return listings.firstOrNull;
}

/// Compute a mount request for the given ship and template.
Future<MountRequest?> mountRequestForShip(
  CentralCommand centralCommand,
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner,
  ShipyardListingSnapshot shipyards,
  Ship ship,
  ShipTemplate template, {
  required int expectedCreditsPerSecond,
}) async {
  final needed = mountsToAddToShip(ship, template);
  if (needed.isEmpty) {
    return null;
  }
  final buyJob = buyJobForMount(
    needed,
    marketPrices,
    routePlanner,
    ship,
    expectedCreditsPerSecond: expectedCreditsPerSecond,
  );
  if (buyJob == null) {
    return null;
  }
  final mountSymbol = mountSymbolForTradeSymbol(buyJob.tradeSymbol)!;

  // Shouldn't be null after buyJob comes back non-null.  We could add a
  // budget to BuyJob instead, that might be better?
  final buyCost = marketPrices.recentPurchasePrice(
    buyJob.tradeSymbol,
    marketSymbol: buyJob.buyLocation,
  );
  if (buyCost == null) {
    return null;
  }
  // Mount costs should be about 3k?  But we don't want to be wrong, as our
  // mount logic will currently just sell the mount right after buying and
  // could get stuck in a loop if we're too tight on credits. We also could
  // record mount credits from the shipyard prices, but don't do that yet.
  const mountCost = 100000;
  final creditsNeeded = buyCost + mountCost;

  final shipyard =
      await nearestShipyard(routePlanner, shipyards, ship.waypointSymbol);
  if (shipyard == null) {
    return null;
  }
  return MountRequest(
    shipSymbol: ship.symbol,
    mountSymbol: mountSymbol,
    marketSymbol: buyJob.buyLocation,
    shipyardSymbol: shipyard.waypointSymbol,
    creditsNeeded: creditsNeeded,
  );
}

/// Generates a buy job for the first mount we know how to find a buy job for.
BuyJob? buyJobForMount(
  MountSymbolSet needed,
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner,
  Ship ship, {
  required int expectedCreditsPerSecond,
}) {
  // Walk through the needed mounts.  Find the first one we have a known
  // buy location for.
  for (final mount in needed) {
    final tradeSymbol = tradeSymbolForMountSymbol(mount);
    final marketTrip = findBestMarketToBuy(
      marketPrices,
      routePlanner,
      tradeSymbol,
      expectedCreditsPerSecond: expectedCreditsPerSecond,
      start: ship.waypointSymbol,
      shipSpec: ship.shipSpec,
    );
    if (marketTrip != null) {
      return BuyJob(
        tradeSymbol: tradeSymbol,
        units: 1,
        buyLocation: marketTrip.route.endSymbol,
      );
    }
  }
  return null;
}

/// Advance the behavior of the given ship.
final advanceMountFromBuy = const MultiJob('Mount from Buy', [
  doBuyJob,
  doMountJob,
]).run;
