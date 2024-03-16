import 'package:cli/behavior/job.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

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
  // TODO(eseidel): Add a way for jobs to get their job name from the MultiJob.
  const jobName = 'BuyJob';
  final buyJob =
      assertNotNull(state.buyJob, 'No buy job', const Duration(hours: 1));

  // If we're currently at a market, record the prices and refuel.
  final maybeMarket = await visitLocalMarket(
    api,
    db,
    caches,
    ship,
    // We want to always be using super up-to-date market prices for the trader.
    maxAge: const Duration(seconds: 5),
  );
  await visitLocalShipyard(
    db,
    api,
    caches.waypoints,
    caches.static,
    caches.agent,
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
    state,
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
      db,
      centralCommand,
      caches,
      ship,
      state,
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
    shipWarn(
      ship,
      '$jobName already has ${buyJob.units} ${buyJob.tradeSymbol}',
    );
    return JobResult.complete();
  }

  if (units <= 0 && existingUnits > 0) {
    shipWarn(
      ship,
      '$jobName already has $existingUnits ${buyJob.tradeSymbol},'
      " can't afford more.",
    );
    return JobResult.complete();
  }

  // Otherwise we're at our buy location and we buy.
  await dockIfNeeded(db, api, ship);

  // TODO(eseidel): Share this code with trader.dart
  final medianPrice = await db.medianMarketPurchasePrice(tradeSymbol);
  final transaction = await purchaseTradeGoodIfPossible(
    api,
    db,
    caches.agent,
    ship,
    good,
    tradeSymbol,
    maxWorthwhileUnitPurchasePrice: null,
    unitsToPurchase: units,
    medianPrice: medianPrice,
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
      '${creditsString(transaction.creditsChange)}',
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
