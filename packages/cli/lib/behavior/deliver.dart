import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

// Go buy and deliver.
// Used for modules.

/// Compute the mounts in the given ship's inventory.
MountSymbolSet countMountsInInventory(Ship ship) {
  final counts = MountSymbolSet();
  for (final item in ship.cargo.inventory) {
    final mountSymbol = mountSymbolForTradeSymbol(item.tradeSymbol);
    // Will be null if the item isn't a mount.
    if (mountSymbol == null) {
      continue;
    }
    counts.add(mountSymbol, item.units);
  }
  return counts;
}

/// Compute the mounts mounted on the given ship.
MountSymbolSet countMountedMounts(Ship ship) {
  return MountSymbolSet.fromIterable(
    ship.mounts.map((m) => m.symbol),
  );
}

/// Mounts to add to make [ship] match [template].
MountSymbolSet mountsToAddToShip(Ship ship, ShipTemplate template) {
  return template.mounts.difference(countMountedMounts(ship));
}

/// Mounts to remove to make [ship] match [template].
MountSymbolSet mountsToRemoveFromShip(
  Ship ship,
  ShipTemplate template,
) {
  return countMountedMounts(ship).difference(template.mounts);
}

class _BuyRequest {
  _BuyRequest({
    required this.tradeSymbol,
    required this.units,
  });

  final TradeSymbol tradeSymbol;
  final int units;
}

_BuyRequest? _buyRequestFromNeededMounts(MountSymbolSet needed) {
  if (needed.isEmpty) {
    return null;
  }
  // Check each of the needed mounts for availability and affordability.

  final mountSymbol = needed.first;
  final units = needed[mountSymbol];
  final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
  return _BuyRequest(tradeSymbol: tradeSymbol, units: units);
}

/// This is an attempt towards a compound job.
class DeliverState {
  /// Create a new deliver state.
  DeliverState(
    this.buyJob, {
    this.jobIndex = 0,
  });

  /// Which job are we on?
  int jobIndex;

  /// The buy job state.
  final BuyJob buyJob;
}

/// Determine what BuyJob to issue, if any.
Future<BuyJob?> computeBuyJob(
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // Figure out if there are any things needing to be delivered.
  // Look at our ore-hounds, see if they are matching spec.
  // If mounts are missing, see if we can buy them.
  final neededMounts = centralCommand.mountsNeededForAllShips();
  jobAssert(
    neededMounts.isNotEmpty,
    'No deliveries needed.',
    const Duration(minutes: 10),
  );

  // Figure out what item we're supposed to get.
  // If so, in what priority?
  // If we can't buy them, disable the behavior for a while.
  final buyRequest = assertNotNull(
    _buyRequestFromNeededMounts(neededMounts),
    'No mounts available.',
    const Duration(minutes: 10),
  );

  final tradeSymbol = buyRequest.tradeSymbol;
  final maxToBuy = buyRequest.units;

  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  jobAssert(
    hqWaypoints.any((w) => w.hasShipyard),
    'No shipyard in $hqSystem',
    const Duration(days: 1),
  );

  // Find the best place to buy it.
  final trip = assertNotNull(
    findBestMarketToBuy(
      caches.marketPrices,
      caches.routePlanner,
      ship,
      tradeSymbol,
      expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
    ),
    'No market to buy $tradeSymbol',
    const Duration(hours: 1),
  );
  // TODO(eseidel): This does not consider the cost of the mounts.
  // Should also be setup to re-compute how many mounts we need when we arrive.
  final buyJob = BuyJob(
    tradeSymbol: tradeSymbol,
    units: maxToBuy,
    // Use price.waypointSymbol in case route is empty.
    buyLocation: trip.price.waypointSymbol,
  );
  return buyJob;
}

/// Execute the BuyJob.
Future<JobResult> doBuyJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final buyJob =
      assertNotNull(state.buyJob, 'No buy job', const Duration(hours: 1));

  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // If we're currently at a market, record the prices and refuel.
  final maybeMarket = await visitLocalMarket(
    api,
    db,
    caches,
    currentWaypoint,
    ship,
    // We want to always be using super up-to-date market prices for the trader.
    maxAge: const Duration(seconds: 5),
  );
  await centralCommand.visitLocalShipyard(
    api,
    db,
    caches.shipyardPrices,
    caches.agent,
    currentWaypoint,
    ship,
  );

  // Regardless of where we are, if we have cargo that isn't part of our deal,
  // try to sell it.
  final result = await handleUnwantedCargoIfNeeded(
    api,
    db,
    centralCommand,
    caches,
    ship,
    maybeMarket,
    buyJob.tradeSymbol,
  );
  if (!result.isComplete) {
    return result;
  }

  // If we aren't at our buy location, go there.
  if (ship.waypointSymbol != buyJob.buyLocation) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      buyJob.buyLocation,
    );
    return JobResult.wait(waitUntil);
  }
  // TODO(eseidel): Should reassess the buyJob now that we've arrived.
  // Sometimes it takes a long time to get here, and we might now need more
  // items than we did when we started.

  final currentMarket = assertNotNull(
    maybeMarket,
    'No market at ${ship.waypointSymbol}',
    const Duration(minutes: 5),
  );

  final tradeSymbol = buyJob.tradeSymbol;
  final good = currentMarket.marketTradeGood(tradeSymbol)!;

  final units = unitsToPurchase(
    good,
    ship,
    buyJob.units,
    credits: caches.agent.agent.credits,
  );

  final existingUnits = ship.countUnits(buyJob.tradeSymbol);
  if (existingUnits >= buyJob.units) {
    shipWarn(ship, 'Deliver already has ${buyJob.units} ${buyJob.tradeSymbol}');
    return JobResult.complete();
  }

  if (units <= 0 && existingUnits > 0) {
    shipWarn(
      ship,
      'Deliver already has $existingUnits ${buyJob.tradeSymbol},'
      " can't afford more.",
    );
    return JobResult.complete();
  }

  // Otherwise we're at our buy location and we buy.
  await dockIfNeeded(api, caches.ships, ship);

  // TODO(eseidel): Share this code with trader.dart
  final transaction = await purchaseTradeGoodIfPossible(
    api,
    db,
    caches.marketPrices,
    caches.agent,
    caches.ships,
    ship,
    good,
    tradeSymbol,
    maxWorthwhileUnitPurchasePrice: null,
    unitsToPurchase: units,
    accountingType: AccountingType.capital,
  );

  if (transaction != null) {
    // Don't record deal transactions, there is no deal for this case?
    final leftToBuy = unitsToPurchase(good, ship, buyJob.units);
    if (leftToBuy > 0) {
      shipInfo(
        ship,
        'Purchased $units of $tradeSymbol, still have '
        '$leftToBuy units we would like to buy, looping.',
      );
      return JobResult.wait(null);
    }
    shipInfo(
      ship,
      'Purchased ${transaction.quantity} ${transaction.tradeSymbol} '
      '@ ${transaction.perUnitPrice} '
      '${creditsString(transaction.creditChange)}',
    );
  }
  jobAssert(
    ship.cargo.countUnits(tradeSymbol) > 0,
    'Unable to purchase $tradeSymbol, giving up on this trade.',
    // Not sure what duration to use?  Zero risks spinning hot.
    const Duration(minutes: 10),
  );

  return JobResult.complete();
}

/// Execute the DeliverJob
Future<JobResult> doDeliverJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final deliverJob = assertNotNull(
    state.deliverJob,
    'No deliver job',
    const Duration(hours: 1),
  );

  // If we're not at our deliver location, go there.
  if (ship.waypointSymbol != deliverJob.waypointSymbol) {
    final waitUntil = await beingNewRouteAndLog(
      api,
      ship,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      deliverJob.waypointSymbol,
    );
    return JobResult.wait(waitUntil);
  }

  // If we've handed out all our items, we're done.
  if (ship.countUnits(deliverJob.tradeSymbol) == 0) {
    return JobResult.complete();
  }
  // Otherwise we wait.
  return JobResult.wait(getNow().add(const Duration(minutes: 5)));
}

/// Init the BuyJob and DeliverJob for DeliverBehavior.
Future<JobResult> doInitJob(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final buyJob = assertNotNull(
    await computeBuyJob(
      centralCommand,
      caches,
      ship,
    ),
    'No buy job',
    const Duration(minutes: 20),
  );

  centralCommand.setBuyJob(ship, buyJob);

  final hqSystem = caches.agent.headquartersSymbol.systemSymbol;
  final hqWaypoints = await caches.waypoints.waypointsInSystem(hqSystem);
  final shipyard = hqWaypoints.firstWhere((w) => w.hasShipyard);

  final deliverJob = DeliverJob(
    tradeSymbol: buyJob.tradeSymbol,
    waypointSymbol: shipyard.waypointSymbol,
  );
  centralCommand.setDeliverJob(ship, deliverJob);
  return JobResult.complete();
}

/// Advance the behavior of the given ship.
final advanceDeliver = const MultiJob('Deliver', [
  doInitJob,
  doBuyJob,
  doDeliverJob,
]).run;

// This seems related to using haulers for delivery of trade goods.
// They get loaded by miners.
// Then their job is how to figure out where to sell it.
// If there isn't a hauler to load to, the miner just sells?
// If the hauler isn't full it just sleeps until full?
