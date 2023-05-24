import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/contract_trader.dart';
import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/ship_waiter.dart';

// At the top of the file because I change this so often.
Behavior _behaviorFor(
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
    // if (maybeGoods != null) {
    //   return Behavior.contractTrader;
    // }
    //   return Behavior.arbitrageTrader;
  }
  // Could check if it has a mining laser or ship.isExcavator
  if (ship.canMine) {
    return Behavior.miner;
  }
  return Behavior.explorer;
}

Future<DateTime?> _advanceShip(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
  BehaviorState behavior,
  Contract? contract,
  ContractDeliverGood? maybeGoods,
) async {
  switch (behavior.behavior) {
    case Behavior.contractTrader:
      // We currently only trigger trader logic if we have a contract.
      return advanceContractTrader(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
        contract!,
        maybeGoods!,
      );
    case Behavior.arbitrageTrader:
      return advanceArbitrageTrader(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
      );
    case Behavior.miner:
      try {
        // This await is very important, if it's not present, exceptions won't
        // be caught until some outer await.
        return await advanceMiner(
          api,
          db,
          priceData,
          agent,
          ship,
          systemWaypoints,
        );
      } on ApiException catch (e) {
        // This handles the ship (reactor?) cooldown exception which we can
        // get when running the script fresh with no state while a ship is
        // still on cooldown from a previous run.
        final expiration = expirationFromApiException(e);
        if (expiration != null) {
          return expiration;
        }
        rethrow;
      }
    case Behavior.explorer:
      return advanceExporer(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
      );
  }
}

BehaviorState? _loadBehaviorState(String shipSymbol) {
  return null;
}

/// One loop of the logic.
Future<void> logicLoop(
  Api api,
  DataStore db,
  PriceData priceData,
  ShipWaiter waiter,
) async {
  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final myShips = await allMyShips(api).toList();
  waiter.updateForShips(myShips);
  final allContracts = await allMyContracts(api).toList();
  // Filter out the ones we've already done.
  final contracts = allContracts.where((c) => !c.fulfilled).toList();
  if (contracts.length > 1) {
    throw UnimplementedError();
  }
  final contract = contracts.firstOrNull;
  final maybeGoods = contract?.terms.deliver.firstOrNull;

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
    // Could cache waypoints between ships.
    final systemWaypoints =
        await waypointsInSystem(api, ship.nav.systemSymbol).toList();
    final previousWait = waiter.waitUntil(ship.symbol);
    if (previousWait != null) {
      continue;
    }
    // We should only generate a new behavior when we're done with our last
    // behavior?
    var behaviorState = _loadBehaviorState(ship.symbol);
    behaviorState ??= BehaviorState(
      _behaviorFor(ship, agent, maybeGoods),
    );
    final waitUntil = await _advanceShip(
      api,
      db,
      priceData,
      agent,
      ship,
      systemWaypoints,
      behaviorState,
      contract,
      maybeGoods,
    );
    waiter.updateWaitUntil(ship.symbol, waitUntil);
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

/// Returns true if the inner exception is a windows semaphore timeout.
/// This is a workaround for some behavior in windows I do not understand.
/// These seem to occur only once every few hours at random.
bool isWindowsSemaphoreTimeout(ApiException e) {
  final innerException = e.innerException;
  if (innerException == null) {
    return false;
  }
  return innerException
      .toString()
      .contains('The semaphore timeout period has expired.');
}

/// Run the logic loop forever.
/// Currently just sends ships to mine and sell ore.
Future<void> logic(Api api, DataStore db, PriceData priceData) async {
  final contractsResponse = await api.contracts.getContracts();
  final contracts = contractsResponse!.data;

  // Don't accept random contracts anymore.
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

  final waiter = ShipWaiter();

  while (true) {
    try {
      await logicLoop(api, db, priceData, waiter);
    } on ApiException catch (e) {
      if (!isWindowsSemaphoreTimeout(e)) {
        rethrow;
      }
      logger.warn('Ignoring windows semaphore timeout exception.');
      // ignore windows semaphore timeout
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
