// Goes to the location it's been told to.
// Waits until full.
// Sells goods for the best price it can.

import 'package:cli/behavior/job.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';

/// Go wait to be filled by miners.
Future<JobResult> goWaitForGoods(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final mineJob = assertNotNull(
    state.extractionJob,
    'No mine job.',
    const Duration(hours: 1),
  );
  final mineSymbol = mineJob.source;

  final currentMineJob = centralCommand.squadForShip(ship)?.job;
  jobAssert(
    currentMineJob == mineJob,
    'Mine job changed',
    const Duration(minutes: 1),
  );
  final currentSellsFuel = await db.marketListings.sellsFuel(
    ship.waypointSymbol,
  );
  final medianFuelPurchasePrice = await db.marketPrices.medianPurchasePrice(
    TradeSymbol.FUEL,
  );

  if (ship.waypointSymbol != mineSymbol) {
    final mineSellsFuel = await db.marketListings.sellsFuel(mineSymbol);
    final fuelToBuy = (ship.frame.fuelCapacity / 100).ceil();
    if (!mineSellsFuel &&
        currentSellsFuel &&
        ship.cargo.availableSpace >= fuelToBuy &&
        fuelToBuy > 0) {
      logger.warn('BUYING FUEL CARGO FOR LATER USE');
      await dockIfNeeded(db, api, ship);
      await purchaseCargoAndLog(
        api,
        db,
        ship,
        TradeSymbol.FUEL,
        AccountingType.fuel,
        amountToBuy: fuelToBuy,
        medianPrice: medianFuelPurchasePrice,
      );
    }

    final waitTime = await beingNewRouteAndLog(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      mineSymbol,
    );
    return JobResult.wait(waitTime);
  }

  // If the mine doesn't sell fuel, and we have fuel, refuel.
  if (!currentSellsFuel &&
      !ship.isFuelFull &&
      ship.cargo.countUnits(TradeSymbol.FUEL) > 0) {
    logger.warn('REFUELING FROM CARGO');
    await dockIfNeeded(db, api, ship);
    await refuelAndLog(
      api,
      db,
      ship,
      medianFuelPurchasePrice: medianFuelPurchasePrice,
      fromCargo: true,
    );
  }

  // Transferring goods requires being the same orbit state.
  await undockIfNeeded(db, api, ship);

  // If we're not yet full, go to sleep for a minute.
  if (ship.cargo.availableSpace > 0) {
    return JobResult.wait(getNow().add(const Duration(minutes: 1)));
  }
  return JobResult.complete();
}

/// Advance the miner hauler.
final advanceMinerHauler = const MultiJob('MinerHauler', [
  emptyCargoIfNeededForMining,
  goWaitForGoods,
  // TODO(eseidel): travelAndSellCargo is likely wrong, it includes
  // miner-specific logic like checking the reactor cooldown.
  travelAndSellCargo,
]).run;
