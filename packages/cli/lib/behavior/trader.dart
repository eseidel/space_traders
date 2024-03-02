import 'dart:math';

import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/exploring.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/plan/market_scores.dart';
import 'package:cli/plan/trading.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

// This is split out from the main function to allow early returns.
/// Public to allow sharing with contract trader (for now).
Future<Transaction?> purchaseTradeGoodIfPossible(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  MarketTradeGood marketGood,
  TradeSymbol neededTradeSymbol, {
  required int? maxWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
  required int? medianPrice,
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
    agentCache,
    ship,
    neededTradeSymbol,
    accountingType,
    amountToBuy: unitsToPurchase,
    medianPrice: medianPrice,
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

Future<JobResult> _handleAtSourceWithDeal(
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
  final maxUnits = costedDeal.maxUnitsToBuy;

  // Could this get confused by having other cargo in our hold?
  final units = unitsToPurchase(good, ship, maxUnits);
  final medianPrice = caches.marketPrices.medianPurchasePrice(dealTradeSymbol);
  if (units > 0) {
    final transaction = await purchaseTradeGoodIfPossible(
      api,
      db,
      caches.agent,
      ship,
      good,
      dealTradeSymbol,
      maxWorthwhileUnitPurchasePrice: maxPerUnitPrice,
      unitsToPurchase: units,
      medianPrice: medianPrice,
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
        return JobResult.wait(null);
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
  jobAssert(
    haveTradeCargo,
    'Unable to purchase $dealTradeSymbol, giving up on this trade.',
    const Duration(seconds: 1),
  );
  // Otherwise we've bought what we can here, this part of the job is done.
  return JobResult.complete();
}

/// Logs a completed deal.
void logCompletedDeal(
  Ship ship,
  CostedDeal completedDeal, {
  DateTime Function() getNow = defaultGetNow,
}) {
  const cpsSlop = 1; // credits/s
  const durationSlop = 0.1; // Percent;
  final duration = getNow().difference(completedDeal.startTime);
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

Future<JobResult> _handleArbitrageDealAtDestination(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market? maybeMarket,
  CostedDeal costedDeal,
) async {
  final currentMarket = assertNotNull(
    maybeMarket,
    'No market at trade destination for $ship at ${ship.waypointSymbol}',
    const Duration(minutes: 10),
  );
  // We're at the destination, sell and clear the deal.
  final transactions = await sellAllCargoAndLog(
    api,
    db,
    caches.marketPrices,
    caches.agent,
    currentMarket,
    ship,
    AccountingType.goods,
  );
  // We don't yet record the completed deal anywhere.
  final completedDeal = costedDeal.byAddingTransactions(transactions);
  logCompletedDeal(ship, completedDeal);
  return JobResult.complete();
}

/// Handle contract deal at destination.
Future<JobResult> _handleContractDealAtDestination(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market? maybeMarket,
  CostedDeal costedDeal,
) async {
  final contractGood = costedDeal.tradeSymbol;
  final contractId = assertNotNull(
    costedDeal.contractId,
    'No contract id.',
    const Duration(minutes: 10),
  );
  final contract = assertNotNull(
    await db.contractById(contractId),
    'No contract.',
    const Duration(minutes: 10),
  );
  final neededGood = contract.goodNeeded(costedDeal.tradeSymbol);
  final maybeContract = await _deliverContractGoodsIfPossible(
    api,
    db,
    caches.agent,
    ship,
    contract,
    neededGood!,
  );

  // If we've delivered enough, complete the contract.
  if (maybeContract != null &&
      maybeContract.goodNeeded(contractGood)!.remainingNeeded <= 0) {
    await _completeContract(
      api,
      db,
      caches,
      ship,
      maybeContract,
    );
  }
  return JobResult.complete();
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
  await caches.agent.updateAgent(Agent.fromOpenApi(data.agent));
  await db.upsertContract(
    Contract.fromOpenApi(data.contract, DateTime.timestamp()),
  );

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

Future<Contract?> _deliverContractGoodsIfPossible(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  Contract beforeDelivery,
  ContractDeliverGood goods,
) async {
  final tradeSymbol = goods.tradeSymbolObject;
  final unitsBefore = ship.countUnits(tradeSymbol);
  jobAssert(
    unitsBefore > 0,
    'No $tradeSymbol to deliver.',
    const Duration(minutes: 10),
  );
  // Prevent exceptions from racing ships:
  // ApiException 400: {"error":{"message":"Failed to update contract.
  // Contract has already been fulfilled.","code":4504,"data":
  // {"contractId":"cljysnr2wt47as60cvz377bhh"}}}
  jobAssert(
    !beforeDelivery.fulfilled,
    'Contract ${beforeDelivery.id} already fulfilled.',
    const Duration(minutes: 10),
  );

  if (!beforeDelivery.accepted) {
    shipErr(
      ship,
      'Contract ${beforeDelivery.id} not accepted? Accepting before delivery.',
    );
    await acceptContractAndLog(
      api,
      db,
      agentCache,
      ship,
      beforeDelivery,
    );
  }

  // And we have the desired cargo.
  final response = await deliverContract(
    db,
    api,
    ship,
    beforeDelivery,
    tradeSymbol: tradeSymbol,
    units: unitsBefore,
  );
  final afterDelivery =
      Contract.fromOpenApi(response.contract, DateTime.timestamp());
  final deliver = assertNotNull(
    afterDelivery.goodNeeded(tradeSymbol),
    'No ContractDeliverGood for $tradeSymbol?',
    const Duration(minutes: 10),
  );
  shipInfo(
    ship,
    'Delivered $unitsBefore ${goods.tradeSymbol} '
    'to ${goods.destinationSymbol}; '
    '${deliver.unitsFulfilled}/${deliver.unitsRequired}, '
    '${approximateDuration(afterDelivery.timeUntilDeadline)} to deadline',
  );

  // Update our cargo counts after delivering the contract goods.
  final unitsAfter = ship.countUnits(tradeSymbol);
  final unitsDelivered = unitsAfter - unitsBefore;

  // Record the delivery transaction.
  final contactTransaction = ContractTransaction.delivery(
    contract: afterDelivery,
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
  return afterDelivery;
}

/// Handle construction deal at destination.
Future<JobResult> _handleConstructionDealAtDelivery(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  BehaviorState state,
  Market? maybeMarket,
  CostedDeal costedDeal,
) async {
  jobAssert(
    costedDeal.deal.destinationSymbol == ship.waypointSymbol,
    'Not at destination.',
    const Duration(minutes: 10),
  );
  final waypointSymbol = costedDeal.deal.destinationSymbol;

  final construction = assertNotNull(
    await caches.construction.getConstruction(waypointSymbol),
    'No construction.',
    const Duration(minutes: 10),
  );
  try {
    await _deliverConstructionMaterialsIfPossible(
      api,
      db,
      caches.agent,
      caches.construction,
      ship,
      construction,
      costedDeal.tradeSymbol,
    );
  } on ApiException catch (e) {
    if (isConstructionRequirementsMet(e)) {
      shipWarn(
        ship,
        'Construction at $waypointSymbol already fulfilled '
        '${costedDeal.tradeSymbol}.',
      );
      return JobResult.complete();
    }
    rethrow;
  }
  return JobResult.complete();
}

Future<SupplyConstruction201ResponseData?>
    _deliverConstructionMaterialsIfPossible(
  Api api,
  Database db,
  AgentCache agentCache,
  ConstructionCache constructionCache,
  Ship ship,
  Construction construction,
  TradeSymbol tradeSymbol, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final unitsInCargo = ship.countUnits(tradeSymbol);
  final waypointName = construction.symbol;
  jobAssert(
    unitsInCargo > 0,
    'No $tradeSymbol to deliver.',
    const Duration(minutes: 10),
  );
  jobAssert(
    !construction.isComplete,
    'Construction at $waypointName already complete.',
    const Duration(minutes: 10),
  );

  final materialBefore = assertNotNull(
    construction.materialNeeded(tradeSymbol),
    'Construction at $waypointName does not need $tradeSymbol?',
    const Duration(minutes: 10),
  );
  final unitsToDeliver = min(unitsInCargo, materialBefore.remainingNeeded);
  jobAssert(
    unitsToDeliver > 0,
    'Construction at $waypointName already fulfilled $tradeSymbol.',
    const Duration(minutes: 10),
  );

  // And we have the desired cargo.
  final response = await supplyConstruction(
    db,
    api,
    ship,
    constructionCache,
    construction,
    tradeSymbol: tradeSymbol,
    units: unitsToDeliver,
  );
  final material = response.construction.materialNeeded(tradeSymbol)!;
  final unitsAfter = ship.countUnits(tradeSymbol);
  final unitsDelivered = unitsAfter - unitsInCargo;
  shipInfo(
    ship,
    'Supplied $unitsDelivered $tradeSymbol to $waypointName; '
    '${material.fulfilled}/${material.required_}',
  );

  // Update our cargo counts after delivering the contract goods.
  ship.cargo = response.cargo;
  await db.upsertShip(ship);

  // Record the delivery transaction.
  final delivery = ConstructionDelivery(
    shipSymbol: ship.shipSymbol,
    waypointSymbol: ship.waypointSymbol,
    unitsDelivered: unitsDelivered,
    tradeSymbol: tradeSymbol,
    timestamp: getNow(),
  );
  final transaction = Transaction.fromConstructionDelivery(
    delivery,
    agentCache.agent.credits,
  );
  await db.insertTransaction(transaction);
  return response;
}

Future<int?> _expectedContractProfit(
  Database db,
  Contract contract,
) async {
  // Add up the total expected outlay.
  final terms = contract.terms;
  final tradeSymbols = terms.deliver.map((d) => d.tradeSymbolObject).toSet();
  final medianPricesBySymbol = <TradeSymbol, int>{};
  for (final tradeSymbol in tradeSymbols) {
    final medianPrice = await db.medianPurchasePrice(tradeSymbol);
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
Future<String> describeExpectedContractProfit(
  Database db,
  Contract contract,
) async {
  final profit = await _expectedContractProfit(db, contract);
  final profitString = profit == null ? 'unknown' : creditsString(profit);
  return 'Expected profit: $profitString';
}

/// Accepts contracts for us if needed.
Future<DateTime?> acceptContractsIfNeeded(
  Api api,
  Database db,
  MarketPriceSnapshot marketPrices,
  AgentCache agentCache,
  Ship ship,
) async {
  /// Accept logic we run any time contract trading is turned on.
  final activeContracts = await db.activeContracts();
  if (activeContracts.isEmpty) {
    final contract = await negotiateContractAndLog(
      db,
      api,
      ship,
    );
    shipInfo(ship, await describeExpectedContractProfit(db, contract));
    return null;
  }
  final unacceptedContracts = await db.unacceptedContracts();
  for (final contract in unacceptedContracts) {
    await acceptContractAndLog(
      api,
      db,
      agentCache,
      ship,
      contract,
    );
  }
  return null;
}

/// Sell or jettison any cargo we don't need.
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
      ship,
      // We don't have a good way to know what type of cargo this is.
      // Assuming it's goods (rather than capital) is probably fine.
      AccountingType.goods,
      where: isNotWantedCargo,
    );
  }

  if (ship.cargo.isEmpty) {
    return JobResult.complete();
  }
  shipInfo(
    ship,
    'Cargo hold not empty, finding market to sell ${unwantedCargo.symbol}.',
  );
  // We can't sell this cargo anywhere so give up?

  final costedTrip = await findBestMarketToSell(
    db,
    caches.marketPrices,
    caches.routePlanner,
    ship,
    unwantedCargo.tradeSymbol,
    expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
    unitsToSell: unwantedCargo.units,
  );
  if (costedTrip == null) {
    shipErr(
      ship,
      'No nearby market to sell ${unwantedCargo.symbol}, jetisoning cargo!',
    );
    // Only jettison the item we don't know how to sell, others might sell.
    await jettisonCargoAndLog(db, api, ship, unwantedCargo);
    if (ship.cargo.isEmpty) {
      return JobResult.complete();
    }
    // If we still have cargo to off-load, loop again.
    return JobResult.wait(null);
  }

  final waitUntil = await beingRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    costedTrip.route,
  );
  return JobResult.wait(waitUntil);
}

/// Sell unwanted cargo before beginning deal.
Future<JobResult> sellUnwantedCargo(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final deal =
      assertNotNull(state.deal, 'No deal.', const Duration(minutes: 10));

  final unwantedCargo = ship.largestCargo(
    where: (i) => i.tradeSymbol != deal.tradeSymbol,
  );
  if (unwantedCargo == null) {
    return JobResult.complete();
  }

  // If we're currently at a market, record the prices and refuel.
  final currentMarket = await visitLocalMarket(
    api,
    db,
    caches,
    ship,
  );

  final cargoResult = await handleUnwantedCargoIfNeeded(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    currentMarket,
    deal.tradeSymbol,
  );
  return cargoResult;
}

/// One loop of pick-up logic.
Future<JobResult> doTraderGetCargo(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  if (ship.waypointSymbol != state.deal!.deal.sourceSymbol) {
    return JobResult.wait(
      await beingNewRouteAndLog(
        api,
        db,
        centralCommand,
        caches,
        ship,
        state,
        state.deal!.deal.sourceSymbol,
      ),
    );
  }

  // If we're currently at a market, record the prices and refuel.
  final maybeMarket = await visitLocalMarket(
    api,
    db,
    caches,
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
    db,
    api,
    caches.waypoints,
    caches.static,
    caches.agent,
    ship,
  );

  final deal =
      assertNotNull(state.deal, 'No deal.', const Duration(minutes: 10));

  // If we ever add support for picking up from haulers this won't be valid.
  final currentMarket = assertNotNull(
    maybeMarket,
    'No market at trade source for $ship at ${ship.waypointSymbol}',
    const Duration(minutes: 10),
  );
  return _handleAtSourceWithDeal(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    currentMarket,
    deal,
  );
}

/// One loop of drop-off logic.
Future<JobResult> doTraderDeliverCargo(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  // doTraderPickupCargo always just completes after purchasing cargo.
  // It's our job to get us to the destination.
  if (ship.waypointSymbol != state.deal!.deal.destinationSymbol) {
    return JobResult.wait(
      await beingNewRouteAndLog(
        api,
        db,
        centralCommand,
        caches,
        ship,
        state,
        state.deal!.deal.destinationSymbol,
      ),
    );
  }

  // If we're currently at a market, record the prices and refuel.
  final maybeMarket = await visitLocalMarket(
    api,
    db,
    caches,
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
    db,
    api,
    caches.waypoints,
    caches.static,
    caches.agent,
    ship,
  );

  final deal =
      assertNotNull(state.deal, 'No deal.', const Duration(minutes: 10));

  final Future<JobResult> Function(
    Api api,
    Database db,
    CentralCommand centralCommand,
    Caches caches,
    Ship ship,
    BehaviorState state,
    Market? maybeMarket,
    CostedDeal costedDeal,
  ) handler;
  if (deal.isContractDeal) {
    handler = _handleContractDealAtDestination;
  } else if (deal.isConstructionDeal) {
    handler = _handleConstructionDealAtDelivery;
  } else {
    handler = _handleArbitrageDealAtDestination;
  }

  return handler(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    maybeMarket,
    deal,
  );
}

/// Initialize a new deal.
Future<JobResult> _initDeal(
  BehaviorState state,
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  if (centralCommand.isContractTradingEnabled) {
    // This requires a ship, hence is done in trader rather than centralCommand.
    // We may need to be in the faction system to accept contracts.
    // This will dock us at the current waypoint if needed.
    await acceptContractsIfNeeded(
      api,
      db,
      caches.marketPrices,
      caches.agent,
      ship,
    );
  }

  final contractSnapshot = await ContractSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);

  // Consider all deals starting at any market within our consideration range.
  var newDeal = centralCommand.findNextDealAndLog(
    caches.agent,
    contractSnapshot,
    caches.marketPrices,
    caches.systems,
    caches.systemConnectivity,
    caches.routePlanner,
    behaviors,
    ship,
    maxTotalOutlay: caches.agent.agent.credits,
  );

  if (newDeal == null) {
    shipWarn(ship, 'No profitable deals near ${ship.nav.waypointSymbol}.');
  } else if (!newDeal.isFeeder &&
      newDeal.expectedProfitPerSecond <
          centralCommand.expectedCreditsPerSecond(ship)) {
    shipWarn(
        ship,
        'Deal expected profit per second too low: '
        '${creditsString(newDeal.expectedProfitPerSecond)}/s');
    newDeal = null; // clear the deal so we search again.
  } else {
    shipInfo(ship, 'Found deal: ${describeCostedDeal(newDeal)}');
    state.deal = newDeal;
    return JobResult.complete();
  }

  final ships = await ShipSnapshot.load(db);
  final avoidSystems = centralCommand
      .otherTraderSystems(ships, behaviors, ship.shipSymbol)
      .toSet();

  // If we don't have a deal, move to a better location and try again.
  final destinationSymbol = assertNotNull(
    findBetterTradeLocation(
      caches.systems,
      caches.systemConnectivity,
      caches.marketPrices,
      findDeal: (Ship ship, WaypointSymbol startSymbol) {
        return centralCommand.findNextDealAndLog(
          caches.agent,
          contractSnapshot,
          caches.marketPrices,
          caches.systems,
          caches.systemConnectivity,
          caches.routePlanner,
          behaviors,
          ship,
          overrideStartSymbol: startSymbol,
          maxTotalOutlay: caches.agent.agent.credits,
        );
      },
      ship,
      avoidSystems: avoidSystems,
      profitPerSecondThreshold: centralCommand.expectedCreditsPerSecond(ship),
    ),
    'Failed to find better location for trader.',
    const Duration(minutes: 10),
  );
  // Navigate to the new location and try to init a deal there.
  final waitUntil = await beingNewRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    destinationSymbol,
  );
  return JobResult.wait(waitUntil);
}

/// Advance the trader.
final advanceTrader = const MultiJob('Trader', [
  _initDeal,
  sellUnwantedCargo,
  doTraderGetCargo,
  doTraderDeliverCargo,
]).run;
