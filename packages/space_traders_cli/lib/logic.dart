import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/arbitrage.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior.dart';
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
  // if (ship.engine.speed > 20) {
  //   if (maybeGoods != null) {
  //     return Behavior.contractTrader;
  //   }
  //   return Behavior.arbitrageTrader;
  // }
  // Could check if it has a mining laser or ship.isExcavator
  return Behavior.miner;
}

/// Either loads a cached survey set or creates a new one if we have a surveyor.
Future<SurveySet?> loadOrCreateSurveySetIfPossible(
  Api api,
  DataStore db,
  Ship ship,
) async {
  final cachedSurveySet = await loadSurveySet(db, ship.nav.waypointSymbol);
  if (cachedSurveySet != null) {
    return cachedSurveySet;
  }
  if (!ship.hasSurveyor) {
    return null;
  }
  // Survey
  final response = await api.fleet.createSurvey(ship.symbol);
  final survey = response!.data;
  final surveySet = SurveySet(
    waypointSymbol: ship.nav.waypointSymbol,
    surveys: survey.surveys,
  );
  await saveSurveySet(db, surveySet);
  shipInfo(ship, 'Surveyed ${ship.nav.waypointSymbol}');
  return null;
}

Survey? _chooseBestSurvey(SurveySet? surveySet) {
  if (surveySet == null) {
    return null;
  }
  // Each Survey can have multiple deposits.  The survey itself has a
  // size.  We should probably choose the most valuable ore based
  // on market price and then choose the largest deposit of that ore?
  if (surveySet.surveys.isEmpty) {
    return null;
  }
  // Just picking at random for now.
  return surveySet.surveys[Random().nextInt(surveySet.surveys.length)];
}

/// Apply the miner behavior to the ship.
Future<DateTime?> advanceMiner(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
) async {
  if (ship.isInTransit) {
    // Just go back to sleep until the ship is done flying.
    return ship.nav.route.arrival;
  }
  final currentWaypoint =
      lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  if (!currentWaypoint.isAsteroidField) {
    // We're not at an asteroid field, so we need to navigate to one.
    final asteroidField = systemWaypoints.firstWhere((w) => w.isAsteroidField);
    return navigateToAndLog(api, ship, asteroidField);
  }
  // It's not worth potentially waiting a minute just to get a few pieces
  // of cargo, when a surveyed mining operation could pull 10+ pieces.
  // Hence selling when we're down to 15 or fewer spaces.
  if (ship.availableSpace < 15) {
    // Otherwise, sell cargo and refuel if needed.
    await dockIfNeeded(api, ship);
    await refuelIfNeededAndLog(api, priceData, agent, ship);
    await sellCargoAndLog(api, priceData, ship);
    return null;
  }

  // If we still have space, mine.
  // Must be undocked before surveying or mining.
  await undockIfNeeded(api, ship);
  // Load a survey set, or if we have surveying capabilities, survey.
  final surveySet = await loadOrCreateSurveySetIfPossible(api, db, ship);
  final maybeSurvey = _chooseBestSurvey(surveySet);
  try {
    final response = await extractResources(api, ship, survey: maybeSurvey);
    final yield_ = response.extraction.yield_;
    final cargo = response.cargo;
    // Could use TradeSymbol.values.reduce() to find the longest symbol.
    shipInfo(
        ship,
        // pickaxe requires an extra space on mac?
        '⛏️  ${yield_.units.toString().padLeft(2)} '
        '${yield_.symbol.padRight(18)} '
        // Space after emoji is needed on windows to not bleed together.
        '📦 ${cargo.units.toString().padLeft(2)}/${cargo.capacity}');
    // We could sell here before putting ourselves to sleep.
    return response.cooldown.expiration;
  } on ApiException catch (e) {
    if (isExpiredSurveyException(e)) {
      // If the survey is expired, delete it and try again.
      await deleteSurveySet(db, ship.nav.waypointSymbol);
      return null;
    }
    rethrow;
  }
}

Future<void> _recordMarketData(PriceData priceData, Market market) async {
  // shipInfo(ship, 'Recording market data');
  final prices = market.tradeGoods
      .map((g) => Price.fromMarketTradeGood(g, market.symbol))
      .toList();
  await priceData.addPrices(prices);
}

void _logDeal(Ship ship, Deal deal) {
  final profitString =
      lightGreen.wrap('+${creditsString(deal.profit * ship.availableSpace)}');
  shipInfo(
      ship,
      'Deal ($profitString): ${deal.tradeSymbol} '
      'for ${creditsString(deal.purchasePrice)}, '
      'sell for ${creditsString(deal.sellPrice)} '
      'at ${deal.destinationSymbol} '
      'profit: ${creditsString(deal.profit)} per unit ');
}

/// One loop of the trading logic
Future<DateTime?> advanceArbitrageTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
) async {
  if (ship.isInTransit) {
    // Do nothing for now.
    return ship.nav.route.arrival;
  }
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint =
      lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);
  if (!currentWaypoint.hasMarketplace) {
    // We are not at a marketplace, nothing to do, other than navigate to the
    // the nearest marketplace to fuel up and try again.
    final nearestMarket = systemWaypoints.where((w) => w.hasMarketplace).reduce(
          (a, b) =>
              a.distanceTo(currentWaypoint) < b.distanceTo(currentWaypoint)
                  ? a
                  : b,
        );
    return navigateToAndLog(api, ship, nearestMarket);
  }

  // We are at a marketplace, so we can trade.
  final allMarkets = await getAllMarkets(api, systemWaypoints).toList();
  final currentMarket = lookupMarket(currentWaypoint.symbol, allMarkets);
  await _recordMarketData(priceData, currentMarket);
  // Sell any cargo we can.
  ship.cargo = await sellCargoAndLog(api, priceData, ship);
  const minimumProfit = 500;
  final deal = await findBestDeal(
    api,
    priceData,
    ship,
    currentWaypoint,
    allMarkets,
    minimumProfitPer: minimumProfit ~/ ship.availableSpace,
  );

  // Deal can return null if there are no markets or all we can
  // see are unprofitable deals, in which case we just try another market.
  if (deal == null) {
    shipInfo(
      ship,
      '🎲 trying another market, no deals >${creditsString(minimumProfit)} '
      'profit at ${currentMarket.symbol}',
    );
    final otherMarkets =
        allMarkets.where((m) => m.symbol != currentMarket.symbol).toList();
    final otherMarket = otherMarkets[Random().nextInt(otherMarkets.length)];
    final waypoint = lookupWaypoint(otherMarket.symbol, systemWaypoints);
    shipInfo(
      ship,
      'Distance: ${currentWaypoint.distanceTo(waypoint)}, '
      'currentFuel: ${ship.fuel.current}',
    );
    return navigateToAndLog(api, ship, waypoint);
  }

  // Otherwise, we have a worthwhile opportunity, so purchase and go!
  _logDeal(ship, deal);
  await purchaseCargoAndLog(
    api,
    priceData,
    ship,
    deal.tradeSymbol.value,
    ship.availableSpace,
  );

  final destination = lookupWaypoint(deal.destinationSymbol, systemWaypoints);
  return navigateToAndLog(api, ship, destination);
}

List<Market> _marketsWithExport(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exports.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

List<Market> _marketsWithExchange(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exchange.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

Future<DeliverContract200ResponseData?> _deliverContractGoodsIfPossible(
  Api api,
  Ship ship,
  Contract contract,
  ContractDeliverGood goods,
) async {
  final units = ship.countUnits(goods.tradeSymbol);
  if (units < 1) {
    return null;
  }
  // And we have the desired cargo.
  final response =
      await deliverContract(api, ship, contract, goods.tradeSymbol, units);
  final deliver = response.contract.goodNeeded(goods.tradeSymbol)!;
  shipInfo(
    ship,
    'Delivered $units ${goods.tradeSymbol} '
    'to ${goods.destinationSymbol}; '
    '${deliver.unitsFulfilled}/${deliver.unitsRequired}, '
    '${durationString(contract.timeUntilDeadline)} to deadline',
  );
  return response;
}

/// One loop of the trading logic
Future<DateTime?> advanceContractTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
  Contract contract,
  ContractDeliverGood goods,
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return ship.nav.route.arrival;
  }
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint =
      lookupWaypoint(ship.nav.waypointSymbol, systemWaypoints);

  final allMarkets = await getAllMarkets(api, systemWaypoints).toList();

  // If we're at our contract destination.
  if (currentWaypoint.symbol == goods.destinationSymbol) {
    final maybeResponse =
        await _deliverContractGoodsIfPossible(api, ship, contract, goods);
    if (maybeResponse != null) {
      // Update our cargo counts after fullfilling the contract.
      ship.cargo = maybeResponse.cargo;
      // If we've delivered enough, complete the contract.
      if (maybeResponse.contract.goodNeeded(goods.tradeSymbol)!.amountNeeded <=
          0) {
        await api.contracts.fulfillContract(contract.id);
        shipInfo(ship, 'Contract complete!');
        return null;
      }
    }

    // Sell anything we have.
    await sellCargoAndLog(api, priceData, ship);
    // nav to place nearby exporting our contract goal.
    // This should also consider the current market.
    var markets = _marketsWithExport(goods.tradeSymbol, allMarkets);
    if (markets.isEmpty) {
      markets = _marketsWithExchange(goods.tradeSymbol, allMarkets);
    }
    final marketSymbol = markets.firstOrNull?.symbol;
    final destination = lookupWaypoint(marketSymbol!, systemWaypoints);
    return navigateToAndLog(api, ship, destination);
  }

  // Otherwise if we're not at our contract destination.
  // And it has a market.
  if (currentWaypoint.hasMarketplace) {
    final market = lookupMarket(currentWaypoint.symbol, allMarkets);
    final maybeGood = market.tradeGoods
        .firstWhereOrNull((g) => g.symbol == goods.tradeSymbol);
    final medianPurchasePrice =
        priceData.medianPurchasePrice(goods.tradeSymbol);
    // And our contract goal is selling < market.
    // Or we don't know what "market" price is.
    if (maybeGood != null &&
        (medianPurchasePrice == null ||
            maybeGood.purchasePrice < medianPurchasePrice)) {
      // Sell everything we have except the contract goal.
      final cargo = await sellCargoAndLog(
        api,
        priceData,
        ship,
        where: (s) => s != goods.tradeSymbol,
      );
      if (cargo.availableSpace > 0) {
        // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
        // Buy a full stock of contract goal.
        await purchaseCargoAndLog(
          api,
          priceData,
          ship,
          goods.tradeSymbol,
          cargo.availableSpace,
        );
      }
    } else {
      // TODO(eseidel): This can't work.  We need to be able to do something
      // when things are too expensive.
      shipInfo(
        ship,
        '${goods.tradeSymbol} is too expensive at ${currentWaypoint.symbol}',
      );
    }
  }
  // Regardless, navigate to contract destination.
  final destination = lookupWaypoint(goods.destinationSymbol, systemWaypoints);
  return navigateToAndLog(api, ship, destination);
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
  final hq = parseWaypointString(agentResult.data.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system).toList();
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

  if (shouldPurchaseMiner(agent, myShips)) {
    logger.info('Purchasing mining drone.');
    final shipyardWaypoint = systemWaypoints.firstWhere((w) => w.hasShipyard);
    final purchaseResponse =
        await purchaseShip(api, ShipType.MINING_DRONE, shipyardWaypoint.symbol);
    logger.info('Purchased ${purchaseResponse.ship.symbol}');
    return; // Fetch ship lists again with no wait.
  }

  // printShips(myShips, systemWaypoints);
  // loop over all mining ships and advance them.
  for (final ship in myShips) {
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
    if (earliestWaitUntil != null) {
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
