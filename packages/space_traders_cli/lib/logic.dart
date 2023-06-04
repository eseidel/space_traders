import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/exceptions.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/ship_waiter.dart';
import 'package:space_traders_cli/surveys.dart';

// At the top of the file because I change this so often.
Behavior _behaviorFor(
  BehaviorManager behaviorManager,
  Ship ship,
  Agent agent,
  ContractDeliverGood? maybeGoods,
) {
  // Only trade if we have a fast enough ship and money to buy the goods.
  // We want some sort of money limit, but currently a money limit can create a
  // bad loop where at limit X, we buy stuff, now under the limit, so we
  // resume mining (instead of trading), sell the stuff we just bought.  We
  // will just continue bouncing at that edge slowly draining our money.
  if (ship.engine.speed > 20) {
    if (maybeGoods != null &&
        behaviorManager.isEnabled(Behavior.contractTrader)) {
      return Behavior.contractTrader;
    }
    // if (behaviorManager.isEnabled(Behavior.arbitrageTrader)) {
    //   return Behavior.arbitrageTrader;
    // }
  }
  // Could check if it has a mining laser or ship.isExcavator
  if (ship.canMine && behaviorManager.isEnabled(Behavior.miner)) {
    return Behavior.miner;
  }
  return Behavior.explorer;
}

/// Returns a list of all active (not fulfilled or expired) contracts.
Future<List<Contract>> activeContracts(Api api) async {
  final allContracts = await allMyContracts(api).toList();
  // Filter out the ones we've already done or have expired.
  return allContracts.where((c) => !c.fulfilled && !c.isExpired).toList();
}

/// One loop of the logic.
Future<void> logicLoop(
  Api api,
  DataStore db,
  PriceData priceData,
  SurveyData surveyData,
  ShipWaiter waiter,
) async {
  final waypointCache = WaypointCache(api);
  final marketCache = MarketCache(waypointCache);
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final myShips = await allMyShips(api).toList();
  waiter.updateForShips(myShips);

  final contracts = await activeContracts(api);
  final maybeContract = contracts.firstOrNull;
  if (contracts.length > 1) {
    throw UnimplementedError("Can't handle multiple contracts yet.");
  }
  final maybeGoods = maybeContract?.terms.deliver.firstOrNull;

  // if (shouldPurchaseMiner(agent, myShips)) {
  //   logger.info('Purchasing mining drone.');
  //   final shipyardWaypoint =
  //      systemWaypoints.firstWhere((w) => w.hasShipyard);
  //   final purchaseResponse =
  //       await purchaseShip(api, ShipType.MINING_DRONE,
  //      shipyardWaypoint.symbol);
  //   logger.info('Purchased ${purchaseResponse.ship.symbol}');
  //   return; // Fetch ship lists again with no wait.
  // }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (final ship in myShips) {
    final previousWait = waiter.waitUntil(ship.symbol);
    if (previousWait != null) {
      continue;
    }
    // We should only generate a new behavior when we're done with our last
    // behavior?
    final behaviorManager = await BehaviorManager.load(db, (bm, shipSymbol) {
      final ship = myShips.firstWhere((s) => s.symbol == shipSymbol);
      return _behaviorFor(bm, ship, agent, maybeGoods);
    });
    try {
      final ctx = BehaviorContext(
        api,
        db,
        priceData,
        ship,
        agent,
        waypointCache,
        marketCache,
        behaviorManager,
        maybeContract,
        maybeGoods,
        surveyData,
      );
      final waitUntil = await advanceShipBehavior(ctx);
      waiter.updateWaitUntil(ship.symbol, waitUntil);
    } on ApiException catch (e) {
      // Handle the ship reactor cooldown exception which we can get when
      // running the script fresh with no state while a ship is still on
      // cooldown from a previous run.
      final expiration = expirationFromApiException(e);
      if (expiration == null) {
        // Was not a reactor cooldown, just rethrow.
        rethrow;
      }
      final difference = expiration.difference(DateTime.now());
      shipInfo(ship, '🥶 for ${durationString(difference)}');
      waiter.updateWaitUntil(ship.symbol, expiration);
    }
  }
}

/// Returns true if we should purchase a new ship.
/// Currently just returns true if we have no mining ships.
bool shouldPurchaseMiner(Agent myAgent, List<Ship> ships) {
  // If we have no mining ships, purchase one.
  if (ships.every((s) => !s.isExcavator)) {
    return true;
  }
  // This should be dynamic based on market prices?
  // Risk is that it will try to purchase and fail (causing an exception).
  return false;
  // return myAgent.credits > 140000;
}

Future<void> _acceptAllContractsIfNeeded(Api api) async {
  final contractsResponse = await api.contracts.getContracts();
  final contracts = contractsResponse!.data;
  for (final contract in contracts) {
    if (!contract.accepted) {
      await api.contracts.acceptContract(contract.id);
      logger
        ..info('Accepted: ${contractDescription(contract)}.')
        ..info(
          'received ${creditsString(contract.terms.payment.onAccepted)}',
        );
    }
  }
}

/// Run the logic loop forever.
/// Currently just sends ships to mine and sell ore.
Future<void> logic(
  Api api,
  DataStore db,
  PriceData priceData,
  SurveyData surveyData,
) async {
  // Accept any contracts we have not yet accepted.
  // This is a bit dangerous because we could accept a contract and then
  // not be able to fulfill it.
  // This also isn't catching maintenance windows.
  await _acceptAllContractsIfNeeded(api);

  final waiter = ShipWaiter();

  while (true) {
    try {
      await logicLoop(api, db, priceData, surveyData, waiter);
    } on ApiException catch (e) {
      if (isMaintenanceWindowException(e)) {
        logger.warn('Server down for maintenance, waiting 1 minute.');
        await Future<void>.delayed(const Duration(minutes: 1));
        continue;
      }

      // Need to handle token changes after reset.
      // ApiException 401: {"error":{"message":"Failed to parse token.
      // Token reset_date does not match the server. Server resets happen on a
      // weekly to bi-weekly frequency during alpha. After a reset, you should
      // re-register your agent. Expected: 2023-06-03, Actual: 2023-05-20",
      // "code":401,"data":{"expected":"2023-06-03","actual":"2023-05-20"}}}

      if (!isWindowsSemaphoreTimeout(e)) {
        rethrow;
      }
      // ignore windows semaphore timeout
      logger.warn('Ignoring windows semaphore timeout exception, waiting 5s.');
      // I've seen up to 4 of these happen in a row, so wait a few seconds for
      // the system to recover.
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    final earliestWaitUntil = waiter.earliestWaitUntil();
    // earliestWaitUntil can be past if an earlier ship needed to wait
    // but then later ships took longer than that wait time to process.
    if (earliestWaitUntil != null &&
        earliestWaitUntil.isAfter(DateTime.now())) {
      // This future waits until the earliest time we think the server
      // will be ready for us to do something.
      final waitDuration = earliestWaitUntil.difference(DateTime.now());
      // Extra space after emoji needed for windows powershell.
      logger.info(
        '⏱️  ${waitDuration.inSeconds}s until ${earliestWaitUntil.toLocal()}',
      );
      await Future<void>.delayed(earliestWaitUntil.difference(DateTime.now()));
    }
    // Otherwise we just loop again immediately and rely on rate limiting in the
    // API client to prevent us from sending requests too quickly.
  }
}
