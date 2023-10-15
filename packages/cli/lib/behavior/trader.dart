import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scores.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

const _maxJumps = 10;
// TODO(eseidel): Make maxWaypoints bigger as routing gets faster.
const _maxWaypoints = 100;

// This is split out from the main function to allow early returns.
/// Public to allow sharing with contract trader (for now).
Future<Transaction?> purchaseTradeGoodIfPossible(
  Api api,
  Database db,
  MarketPrices marketPrices,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
  MarketTradeGood marketGood,
  TradeSymbol neededTradeSymbol, {
  required int? maxWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
  AccountingType accountingType = AccountingType.goods,
}) async {
  if (unitsToPurchase <= 0) {
    shipWarn(ship, 'Tried to purchase $unitsToPurchase of $neededTradeSymbol?');
    return null;
  }

  // And its selling at a reasonable price.
  // If the market is above maxWorthwhileUnitPurchasePrice and we don't have any
  // cargo yet then we give up and try again.
  if (maxWorthwhileUnitPurchasePrice != null &&
      marketGood.purchasePrice >= maxWorthwhileUnitPurchasePrice) {
    shipInfo(
      ship,
      '$neededTradeSymbol is too expensive at ${ship.waypointSymbol} '
      'needed < $maxWorthwhileUnitPurchasePrice, '
      'got ${marketGood.purchasePrice}',
    );
    return null;
  }

  if (ship.cargo.availableSpace <= 0) {
    shipInfo(
      ship,
      'No cargo space available to purchase $neededTradeSymbol',
    );
    return null;
  }

  // Do we need to guard against insufficient credits here?
  final result = await purchaseCargoAndLog(
    api,
    db,
    marketPrices,
    agentCache,
    shipCache,
    ship,
    neededTradeSymbol,
    unitsToPurchase,
    accountingType,
  );
  return result;
}

/// Returns the number of units we should purchase considering the ship
/// cargo size and the market trade volume as well as any maximum units
/// the deal proscribes.
int unitsToPurchase(
  MarketTradeGood good,
  Ship ship,
  int maxUnitsToBuy, {
  int? credits,
}) {
  // Many market goods trade in batches much smaller than our cargo hold
  // e.g. 10 vs. 120, if we try to buy 120 we'll get an error.
  final unitsInCargo = ship.cargo.countUnits(good.tradeSymbol);
  final unitsLeftToBuy = maxUnitsToBuy - unitsInCargo;

  final marketTradeVolume = good.tradeVolume;
  final unitsToPurchase = min(marketTradeVolume, ship.availableSpace);
  // Some deals have limited size (like contracts) for normal arbitrage deals
  // costedDeal.cargoSize == ship.cargoSpace.
  final contactLimited = min(unitsToPurchase, unitsLeftToBuy);
  final maxFromCredits = credits == null ? null : credits ~/ good.purchasePrice;
  final maxUnits = min(contactLimited, maxFromCredits ?? unitsToPurchase);
  return maxUnits;
}

Future<DateTime?> _handleAtSourceWithDeal(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final dealTradeSymbol = costedDeal.tradeSymbol;
  final good = currentMarket.marketTradeGood(dealTradeSymbol)!;

  final maxPerUnitPrice = costedDeal.maxPurchaseUnitPrice;
  final nextExpectedPrice = costedDeal.predictNextPurchasePrice;

  // Could this get confused by having other cargo in our hold?
  final units = unitsToPurchase(good, ship, costedDeal.maxUnitsToBuy);
  if (units > 0) {
    final transaction = await purchaseTradeGoodIfPossible(
      api,
      db,
      caches.marketPrices,
      caches.agent,
      caches.ships,
      ship,
      good,
      dealTradeSymbol,
      maxWorthwhileUnitPurchasePrice: maxPerUnitPrice,
      unitsToPurchase: units,
    );

    if (transaction != null) {
      // Record the transaction in our deal.
      // TODO(eseidel): Probably better to add a DealId to Transaction?
      state.deal = state.deal!.byAddingTransactions([transaction]);
      final leftToBuy = unitsToPurchase(good, ship, costedDeal.maxUnitsToBuy);
      if (leftToBuy > 0) {
        shipInfo(
          ship,
          'Purchased $units of $dealTradeSymbol, still have '
          '$leftToBuy units we would like to buy, looping.',
        );
        return null;
      }
      shipInfo(
        ship,
        'Purchased ${transaction.quantity} ${transaction.tradeSymbol} '
        '@ ${transaction.perUnitPrice} (expected '
        '${creditsString(nextExpectedPrice)}) = '
        '${creditsString(transaction.creditsChange)}',
      );
    }
  }

  final haveTradeCargo = ship.cargo.countUnits(dealTradeSymbol) > 0;
  if (!haveTradeCargo) {
    // We couldn't buy any cargo, so we're done with this deal.
    shipWarn(
      ship,
      'Unable to purchase $dealTradeSymbol, giving up on this trade.',
    );
    state.isComplete = true;
    return null;
  }
  // Otherwise we've bought what we can here, deliver what we have.
  // TODO(eseidel): Could use beginRouteAndLog instead?
  // That might work?  Note costedDeal.route is more than just source->dest
  // it also includes the work to get to source.
  return beingNewRouteAndLog(
    api,
    ship,
    state,
    caches.ships,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    costedDeal.route.endSymbol,
  );
}

void _logCompletedDeal(Ship ship, CostedDeal completedDeal) {
  const cpsSlop = 1; // credits/s
  const durationSlop = 0.1; // Percent;
  final duration = DateTime.timestamp().difference(completedDeal.startTime);
  final expectedDuration = completedDeal.expectedTime;
  final message =
      'Expected ${creditsString(completedDeal.expectedProfit)} profit '
      '(${creditsString(completedDeal.expectedProfitPerSecond)}/s), got '
      '${creditsString(completedDeal.actualProfit)} '
      '(${creditsString(completedDeal.actualProfitPerSecond)}/s) '
      'in ${durationString(duration)}, '
      'expected ${durationString(expectedDuration)}';
  final durationDiff = duration - expectedDuration;
  final durationDiffPercent =
      (durationDiff.inSeconds / expectedDuration.inSeconds).abs();
  final cpsDiff = (completedDeal.actualProfitPerSecond -
          completedDeal.expectedProfitPerSecond)
      .abs();
  final useWarn = cpsDiff > cpsSlop || durationDiffPercent > durationSlop;
  final useErr = completedDeal.actualProfitPerSecond < 0;
  if (useErr) {
    shipErr(ship, message);
  } else if (useWarn) {
    shipWarn(ship, message);
  } else {
    shipInfo(ship, message);
  }
}

Future<DateTime?> _handleArbitrageDealAtDestination(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  // We're at the destination, sell and clear the deal.
  final transactions = await sellAllCargoAndLog(
    api,
    db,
    caches.marketPrices,
    caches.agent,
    currentMarket,
    caches.ships,
    ship,
    AccountingType.goods,
  );
  // We don't yet record the completed deal anywhere.
  final completedDeal = costedDeal.byAddingTransactions(transactions);
  _logCompletedDeal(ship, completedDeal);
  state.isComplete = true;
  return null;
}

/// Handle contract deal at destination.
Future<DateTime?> _handleContractDealAtDestination(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final contractGood = costedDeal.tradeSymbol;
  final contract = caches.contracts.contract(costedDeal.contractId!);
  final neededGood = contract!.goodNeeded(costedDeal.tradeSymbol);
  final maybeResponse = await _deliverContractGoodsIfPossible(
    api,
    db,
    caches.agent,
    caches.contracts,
    caches.ships,
    ship,
    contract,
    neededGood!,
  );

  // Delivering the goods counts as completing the behavior, we'll
  // decide next loop if we need to do more.
  state.isComplete = true;

  // If we've delivered enough, complete the contract.
  if (maybeResponse != null &&
      maybeResponse.contract.goodNeeded(contractGood)!.amountNeeded <= 0) {
    await _completeContract(
      api,
      db,
      caches,
      ship,
      maybeResponse.contract,
    );
    return null;
  }
  return null;
}

Future<void> _completeContract(
  Api api,
  Database db,
  Caches caches,
  Ship ship,
  Contract contract,
) async {
  final response = await api.contracts.fulfillContract(contract.id);
  final data = response!.data;
  caches.agent.agent = data.agent;
  caches.contracts.updateContract(data.contract);

  final contactTransaction = ContractTransaction.fulfillment(
    contract: contract,
    shipSymbol: ship.shipSymbol,
    waypointSymbol: ship.waypointSymbol,
    timestamp: DateTime.timestamp(),
  );
  final transaction = Transaction.fromContractTransaction(
    contactTransaction,
    caches.agent.agent.credits,
  );
  await db.insertTransaction(transaction);
  shipInfo(ship, 'Contract complete!');
}

Future<DeliverContract200ResponseData?> _deliverContractGoodsIfPossible(
  Api api,
  Database db,
  AgentCache agentCache,
  ContractCache contractCache,
  ShipCache shipCache,
  Ship ship,
  Contract contract,
  ContractDeliverGood goods,
) async {
  final units = ship.countUnits(goods.tradeSymbolObject);
  if (units < 1) {
    return null;
  }
  if (contract.fulfilled) {
    // Prevent exceptions from racing ships:
    // ApiException 400: {"error":{"message":"Failed to update contract.
    // Contract has already been fulfilled.","code":4504,"data":
    // {"contractId":"cljysnr2wt47as60cvz377bhh"}}}
    shipWarn(ship, 'Contract ${contract.id} already fulfilled, ignoring.');
    // Caller will complete behavior.
    return null;
  }

  final unitsBefore = ship.countUnits(goods.tradeSymbolObject);
  // And we have the desired cargo.
  final response = await deliverContract(
    api,
    ship,
    shipCache,
    contractCache,
    contract,
    tradeSymbol: goods.tradeSymbolObject,
    units: units,
  );
  final deliver = response.contract.goodNeeded(goods.tradeSymbolObject)!;
  shipInfo(
    ship,
    'Delivered $units ${goods.tradeSymbol} '
    'to ${goods.destinationSymbol}; '
    '${deliver.unitsFulfilled}/${deliver.unitsRequired}, '
    '${approximateDuration(contract.timeUntilDeadline)} to deadline',
  );

  // Update our cargo counts after delivering the contract goods.
  final unitsAfter = ship.countUnits(goods.tradeSymbolObject);
  final unitsDelivered = unitsAfter - unitsBefore;

  // Record the delivery transaction.
  final contactTransaction = ContractTransaction.delivery(
    contract: contract,
    shipSymbol: ship.shipSymbol,
    waypointSymbol: ship.waypointSymbol,
    unitsDelivered: unitsDelivered,
    timestamp: DateTime.timestamp(),
  );
  final transaction = Transaction.fromContractTransaction(
    contactTransaction,
    agentCache.agent.credits,
  );
  await db.insertTransaction(transaction);
  return response;
}

Future<DateTime?> _handleOffCourseWithDeal(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  CostedDeal costedDeal,
) {
  final haveDealCargo = ship.cargo.countUnits(costedDeal.tradeSymbol) > 0;
  if (!haveDealCargo) {
    // We don't have the cargo we need, so go get it.
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      costedDeal.deal.sourceSymbol,
    );
  } else {
    shipInfo(ship, 'Off course in route to deal, resuming route.');
    // We have the cargo we need, so go sell it.
    // TODO(eseidel): Could this use beginRouteAndLog instead?
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      costedDeal.route.endSymbol,
    );
  }
}

Future<DateTime?> _handleAtDestinationWithDeal(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market currentMarket,
  CostedDeal costedDeal,
) {
  final haveDealCargo = ship.cargo.countUnits(costedDeal.tradeSymbol) > 0;
  if (!haveDealCargo) {
    // We don't have any deal cargo, so we must have just gotten a new
    // deal which *ends* here, but we haven't gotten the cargo yet, go get it.
    return beingNewRouteAndLog(
      api,
      ship,
      state,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      costedDeal.deal.sourceSymbol,
    );
  }
  if (costedDeal.isContractDeal) {
    return _handleContractDealAtDestination(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      currentMarket,
      costedDeal,
    );
  }
  return _handleArbitrageDealAtDestination(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    currentMarket,
    costedDeal,
  );
}

Future<DateTime?> _handleDeal(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  CostedDeal costedDeal,
  Ship ship,
  BehaviorState state,
  Market? currentMarket,
) async {
  // If we're at the source buy the cargo.
  if (costedDeal.deal.sourceSymbol == ship.waypointSymbol) {
    if (currentMarket == null) {
      throw StateError(
        'No currentMarket for $ship at ${ship.waypointSymbol}',
      );
    }
    return _handleAtSourceWithDeal(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      currentMarket,
      costedDeal,
    );
  }
  // If we're at the destination of the deal, sell.
  if (costedDeal.deal.destinationSymbol == ship.waypointSymbol) {
    if (currentMarket == null) {
      throw StateError(
        'No currentMarket for $ship at ${ship.waypointSymbol}',
      );
    }
    return _handleAtDestinationWithDeal(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      currentMarket,
      costedDeal,
    );
  }
  return _handleOffCourseWithDeal(
    api,
    centralCommand,
    caches,
    ship,
    state,
    costedDeal,
  );
}

int? _expectedContractProfit(Contract contract, MarketPrices marketPrices) {
  // Add up the total expected outlay.
  final terms = contract.terms;
  final tradeSymbols = terms.deliver.map((d) => d.tradeSymbolObject).toSet();
  final medianPricesBySymbol = <TradeSymbol, int>{};
  for (final tradeSymbol in tradeSymbols) {
    final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol);
    if (medianPrice == null) {
      return null;
    }
    medianPricesBySymbol[tradeSymbol] = medianPrice;
  }

  final expectedOutlay = terms.deliver
      .map(
        (d) => medianPricesBySymbol[d.tradeSymbolObject]! * d.unitsRequired,
      )
      .fold(0, (sum, e) => sum + e);
  final payment = contract.terms.payment;
  final reward = payment.onAccepted + payment.onFulfilled;
  return reward - expectedOutlay;
}

/// Returns a string describing the expected profit of a contract.
String describeExpectedContractProfit(
  MarketPrices marketPrices,
  Contract contract,
) {
  final profit = _expectedContractProfit(contract, marketPrices);
  final profitString = profit == null ? 'unknown' : creditsString(profit);
  return 'Expected profit: $profitString';
}

/// Accepts contracts for us if needed.
Future<DateTime?> acceptContractsIfNeeded(
  Api api,
  Database db,
  ContractCache contractCache,
  MarketPrices marketPrices,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
) async {
  /// Accept logic we run any time contract trading is turned on.
  final contracts = contractCache.activeContracts;
  if (contracts.isEmpty) {
    final contract =
        await negotiateContractAndLog(api, ship, shipCache, contractCache);
    shipInfo(ship, describeExpectedContractProfit(marketPrices, contract));
    return null;
  }
  for (final contract in contractCache.unacceptedContracts) {
    await acceptContractAndLog(
      api,
      db,
      contractCache,
      agentCache,
      ship,
      contract,
    );
  }
  return null;
}

Future<DateTime?> _navigateToBetterTradeLocation(
  Api api,
  CentralCommand centralCommand,
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  AgentCache agentCache,
  ContractCache contractCache,
  MarketPrices marketPrices,
  ShipCache shipCache,
  Ship ship,
  BehaviorState state,
  String why,
) async {
  shipWarn(ship, why);
  CostedDeal? findDeal(Ship ship, WaypointSymbol startSymbol) {
    return centralCommand.findNextDeal(
      agentCache,
      contractCache,
      marketPrices,
      systemsCache,
      routePlanner,
      ship,
      overrideStartSymbol: startSymbol,
      maxJumps: _maxJumps,
      maxTotalOutlay: agentCache.agent.credits,
      maxWaypoints: _maxWaypoints,
    );
  }

  final destinationSymbol = assertNotNull(
    findBetterTradeLocation(
      systemsCache,
      marketPrices,
      findDeal,
      ship,
      avoidSystems: centralCommand.otherTraderSystems(ship.shipSymbol).toSet(),
      profitPerSecondThreshold: centralCommand.expectedCreditsPerSecond(ship),
    ),
    'Failed to find better location for trader.',
    const Duration(minutes: 10),
  );
  final waitUntil = await beingNewRouteAndLog(
    api,
    ship,
    state,
    shipCache,
    systemsCache,
    routePlanner,
    centralCommand,
    destinationSymbol,
  );
  return waitUntil;
}

/// Sell any cargo we don't need.
Future<JobResult> handleUnwantedCargoIfNeeded(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market? currentMarket,
  TradeSymbol? wantedTradeSymbol,
) async {
  final wantedCargo = ship.largestCargo(
    where: (i) => i.tradeSymbol == wantedTradeSymbol,
  );
  // If tradeSymbol is null, all cargo is "non-deal cargo".
  // Pick the largest as an example, we'll try to sell it all regardless.
  final unwantedCargo = ship.largestCargo(
    where: (i) => i.tradeSymbol != wantedTradeSymbol,
  );

  if (unwantedCargo == null) {
    return JobResult.complete();
  }

  bool isNotWantedCargo(TradeSymbol symbol) =>
      symbol != wantedCargo?.tradeSymbol;
  if (currentMarket != null) {
    await sellAllCargoAndLog(
      api,
      db,
      caches.marketPrices,
      caches.agent,
      currentMarket,
      caches.ships,
      ship,
      // We don't have a good way to know what type of cargo this is.
      // Assuming it's goods (rather than captial) is probably fine.
      AccountingType.goods,
      where: isNotWantedCargo,
    );
  }

  if (ship.cargo.isEmpty) {
    return JobResult.complete();
  }
  shipInfo(
    ship,
    'Cargo hold still not empty, finding '
    'market to sell ${unwantedCargo.symbol}.',
  );
  // We can't sell this cargo anywhere so give up?

  final costedTrip = assertNotNull(
    findBestMarketToSell(
      caches.marketPrices,
      caches.routePlanner,
      ship,
      unwantedCargo.tradeSymbol,
      expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
      unitsToSell: unwantedCargo.units,
    ),
    'No market for ${unwantedCargo.symbol}.',
    const Duration(hours: 1),
  );
  final waitUntil = await beingRouteAndLog(
    api,
    ship,
    state,
    caches.ships,
    caches.systems,
    centralCommand,
    costedTrip.route,
  );
  return JobResult.wait(waitUntil);
}

/// One loop of the trading logic
Future<DateTime?> advanceTrader(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // If we're currently at a market, record the prices and refuel.
  final currentMarket = await visitLocalMarket(
    api,
    db,
    caches,
    currentWaypoint,
    ship,
    // We want to always be using super up-to-date market prices for the trader.
    // If we don't do this, we will end up buying based on stale prices
    // which will make us think the goods are cheaper than they are
    // and buy too many of them.
    // TODO(eseidel): We can fix this by modeling the change in price
    // and thus not having to update?
    maxAge: const Duration(milliseconds: 300),
  );
  await visitLocalShipyard(
    api,
    db,
    caches.shipyardPrices,
    caches.static.shipyardShips,
    caches.agent,
    currentWaypoint,
    ship,
  );

  if (centralCommand.isContractTradingEnabled) {
    await acceptContractsIfNeeded(
      api,
      db,
      caches.contracts,
      caches.marketPrices,
      caches.agent,
      caches.ships,
      ship,
    );
  }

  final pastDeal = state.deal;
  // Regardless of where we are, if we have cargo that isn't part of our deal,
  // try to sell it.
  final result = await handleUnwantedCargoIfNeeded(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    currentMarket,
    pastDeal?.tradeSymbol,
  );
  if (result.shouldReturn) {
    return result.waitTime;
  }

  // We already have a deal, handle it.
  if (pastDeal != null) {
    final waitUntil = await _handleDeal(
      api,
      db,
      centralCommand,
      caches,
      pastDeal,
      ship,
      state,
      currentMarket,
    );
    return waitUntil;
  }

  // We don't have a current deal, so get a new one:
  // Consider all deals starting at any market within our consideration range.
  final newDeal = centralCommand.findNextDeal(
    caches.agent,
    caches.contracts,
    caches.marketPrices,
    caches.systems,
    caches.routePlanner,
    ship,
    maxJumps: _maxJumps,
    maxWaypoints: _maxWaypoints,
    maxTotalOutlay: caches.agent.agent.credits,
  );

  Future<DateTime?> findBetterLocation(String why) async {
    final waitUntil = await _navigateToBetterTradeLocation(
      api,
      centralCommand,
      caches.systems,
      caches.routePlanner,
      caches.agent,
      caches.contracts,
      caches.marketPrices,
      caches.ships,
      ship,
      state,
      why,
    );
    return waitUntil;
  }

  if (newDeal == null) {
    final waitUntil =
        await findBetterLocation('No profitable deals within $_maxJumps jumps '
            'of ${ship.systemSymbol}.');
    return waitUntil;
  }
  if (newDeal.expectedProfitPerSecond <
      centralCommand.expectedCreditsPerSecond(ship)) {
    final waitUntil =
        await findBetterLocation('Deal expected profit per second too low: '
            '${creditsString(newDeal.expectedProfitPerSecond)}/s');
    return waitUntil;
  }

  shipInfo(ship, 'Found deal: ${describeCostedDeal(newDeal)}');
  state.deal = newDeal;
  final waitUntil = await _handleDeal(
    api,
    db,
    centralCommand,
    caches,
    newDeal,
    ship,
    state,
    currentMarket,
  );
  return waitUntil;
}
