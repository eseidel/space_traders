import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/jobs/buy_job.dart';
import 'package:cli/behavior/jobs/mount_job.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/trading.dart';
import 'package:types/types.dart';

/// Compute a mount request for the given ship and template.
Future<MountRequest?> mountRequestForShip(
  CentralCommand centralCommand,
  Caches caches,
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
    caches.marketPrices,
    caches.routePlanner,
    ship,
    expectedCreditsPerSecond: expectedCreditsPerSecond,
  );
  if (buyJob == null) {
    return null;
  }
  final mountSymbol = mountSymbolForTradeSymbol(buyJob.tradeSymbol)!;

  // Shouldn't be null after buyJob comes back non-null.  We could add a
  // budget to BuyJob instead, that might be better?
  final buyCost = caches.marketPrices.recentPurchasePrice(
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

  // TODO(eseidel): Use a nearestShipyard function.
  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = hqWaypoints.firstWhere((w) => w.hasShipyard);
  return MountRequest(
    shipSymbol: ship.shipSymbol,
    mountSymbol: mountSymbol,
    marketSymbol: buyJob.buyLocation,
    shipyardSymbol: shipyard.waypointSymbol,
    creditsNeeded: creditsNeeded,
  );
}

/// Generates a buy job for the first mount we know how to find a buy job for.
BuyJob? buyJobForMount(
  MountSymbolSet needed,
  MarketPrices marketPrices,
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
      ship,
      tradeSymbol,
      expectedCreditsPerSecond: expectedCreditsPerSecond,
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
