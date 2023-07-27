import 'dart:math';

import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/deliver.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

const _maxJumps = 10;
// TODO(eseidel): Make maxWaypoints bigger as routing gets faster.
const _maxWaypoints = 100;

// This is split out from the main function to allow early returns.
/// Public to allow sharing with contract trader (for now).
Future<Transaction?> purchaseTradeGoodIfPossible(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Ship ship,
  MarketTradeGood marketGood,
  TradeSymbol neededTradeSymbol, {
  required int? maxWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
  AccountingType accountingType = AccountingType.goods,
}) async {
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
  // e.g.
//     final creditsNeeded = unitsToPurchase * maybeGood.purchasePrice;
//     if (caches.agent.agent.credits < creditsNeeded) {
//       // If we have some to deliver, deliver it.
//       if (unitsInCargo > 0) {
//         shipInfo(
//           ship,
//           'Not enough credits to purchase $unitsToPurchase '
//           '${neededGood.tradeSymbol} at ${currentWaypoint.symbol}, '
//           'but we have $unitsInCargo in cargo, delivering.',
//         );
//       } else {
//         // This should print the pricing of the good we're trying to buy.
//         await centralCommand.disableBehavior(
//           ship,
//           Behavior.contractTrader,
//           'Not enough credits to purchase $unitsToPurchase '
//           '${neededGood.tradeSymbol} at ${currentWaypoint.symbol}',
//           const Duration(hours: 1),
//         );
//         return null;
//       }
//     }
//   }

  final result = await purchaseCargoAndLog(
    api,
    marketPrices,
    transactionLog,
    agentCache,
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
int unitsToPurchase(MarketTradeGood good, Ship ship, int maxUnitsToBuy) {
  // Many market goods trade in batches much smaller than our cargo hold
  // e.g. 10 vs. 120, if we try to buy 120 we'll get an error.
  final unitsInCargo = ship.cargo.countUnits(good.tradeSymbol);
  final unitsLeftToBuy = maxUnitsToBuy - unitsInCargo;

  final marketTradeVolume = good.tradeVolume;
  final unitsToPurchase = min(marketTradeVolume, ship.availableSpace);
  // Some deals have limited size (like contracts) for normal arbitrage deals
  // costedDeal.cargoSize == ship.cargoSpace.
  return min(unitsToPurchase, unitsLeftToBuy);
}

Future<DateTime?> _handleAtSourceWithDeal(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final dealTradeSymbol = costedDeal.tradeSymbol;
  final good = currentMarket.marketTradeGood(dealTradeSymbol)!;

  final maxPerUnitPrice = costedDeal.maxPurchaseUnitPrice;

  // Could this get confused by having other cargo in our hold?
  final units = unitsToPurchase(good, ship, costedDeal.maxUnitsToBuy);
  if (units > 0) {
    final transaction = await purchaseTradeGoodIfPossible(
      api,
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      ship,
      good,
      dealTradeSymbol,
      maxWorthwhileUnitPurchasePrice: maxPerUnitPrice,
      unitsToPurchase: units,
    );

    if (transaction != null) {
      await centralCommand.recordDealTransactions(ship, [transaction]);
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
        '${costedDeal.deal.purchasePrice}) = '
        '${creditsString(transaction.creditChange)}',
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
    centralCommand.completeBehavior(ship.shipSymbol);
    return null;
  }
  // Otherwise we've bought what we can here, deliver what we have.
  // TODO(eseidel): Could use beginRouteAndLog instead?
  // That might work?  Note costedDeal.route is more than just source->dest
  // it also includes the work to get to source.
  return beingNewRouteAndLog(
    api,
    ship,
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
  if (useWarn) {
    shipWarn(ship, message);
  } else {
    shipInfo(ship, message);
  }
}

Future<DateTime?> _handleArbitrageDealAtDestination(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  // We're at the destination, sell and clear the deal.
  final transactions = await sellAllCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    currentMarket,
    ship,
    AccountingType.goods,
  );
  // We don't yet record the completed deal anywhere.
  final completedDeal = costedDeal.byAddingTransactions(transactions);
  _logCompletedDeal(ship, completedDeal);
  centralCommand.completeBehavior(ship.shipSymbol);
  return null;
}

/// Handle contract deal at destination.
Future<DateTime?> _handleContractDealAtDestination(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final contractGood = costedDeal.tradeSymbol;
  final contract = caches.contracts.contract(costedDeal.contractId!);
  final neededGood = contract!.goodNeeded(costedDeal.tradeSymbol);
  final maybeResponse = await _deliverContractGoodsIfPossible(
    api,
    caches.contracts,
    caches.ships,
    ship,
    contract,
    neededGood!,
  );

  // Delivering the goods counts as completing the behavior, we'll
  // decide next loop if we need to do more.
  centralCommand.completeBehavior(ship.shipSymbol);

  if (maybeResponse != null) {
    // Update our cargo counts after fulfilling the contract.
    ship.cargo = maybeResponse.cargo;
    // If we've delivered enough, complete the contract.
    if (maybeResponse.contract.goodNeeded(contractGood)!.amountNeeded <= 0) {
      final response = await api.contracts.fulfillContract(contract.id);
      final data = response!.data;
      caches.agent.agent = data.agent;
      caches.contracts.updateContract(data.contract);
      shipInfo(ship, 'Contract complete!');
      return null;
    }
  }
  return null;
}

Future<DeliverContract200ResponseData?> _deliverContractGoodsIfPossible(
  Api api,
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
  return response;
}

Future<DateTime?> _handleOffCourseWithDeal(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  CostedDeal costedDeal,
) {
  final haveDealCargo = ship.cargo.countUnits(costedDeal.tradeSymbol) > 0;
  if (!haveDealCargo) {
    // We don't have the cargo we need, so go get it.
    return beingNewRouteAndLog(
      api,
      ship,
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
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
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
      centralCommand,
      caches,
      ship,
      currentMarket,
      costedDeal,
    );
  }
  return _handleArbitrageDealAtDestination(
    api,
    centralCommand,
    caches,
    ship,
    currentMarket,
    costedDeal,
  );
}

Future<DateTime?> _handleDeal(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  CostedDeal costedDeal,
  Ship ship,
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
      centralCommand,
      caches,
      ship,
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
      centralCommand,
      caches,
      ship,
      currentMarket,
      costedDeal,
    );
  }
  return _handleOffCourseWithDeal(
    api,
    centralCommand,
    caches,
    ship,
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
    await acceptContractAndLog(api, contractCache, agentCache, contract);
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
  String why,
) async {
  shipWarn(ship, why);
  final destinationSymbol = await centralCommand.findBetterTradeLocation(
    systemsCache,
    routePlanner,
    agentCache,
    contractCache,
    marketPrices,
    ship,
    maxJumps: _maxJumps,
    maxWaypoints: _maxWaypoints,
  );
  if (destinationSymbol == null) {
    centralCommand.disableBehaviorForShip(
      ship,
      'Failed to find better location for trader.',
      const Duration(hours: 1),
    );
    return null;
  }
  final waitUntil = await beingNewRouteAndLog(
    api,
    ship,
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
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
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
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      currentMarket,
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
  final costedTrip = findBestMarketToSell(
    caches.marketPrices,
    caches.routePlanner,
    ship,
    unwantedCargo.tradeSymbol,
    expectedCreditsPerSecond: centralCommand.expectedCreditsPerSecond(ship),
  );
  if (costedTrip == null) {
    // We can't sell this cargo anywhere so give up?
    return JobResult.error(
      'No market for ${unwantedCargo.symbol}.',
      const Duration(hours: 1),
    );
  }
  final waitUntil = await beingRouteAndLog(
    api,
    ship,
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
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  assert(!ship.isInTransit, 'Ship ${ship.symbol} is in transit');

  final currentWaypoint = await caches.waypoints.waypoint(ship.waypointSymbol);

  // If we're currently at a market, record the prices and refuel.
  final currentMarket = await visitLocalMarket(
    api,
    caches,
    currentWaypoint,
    ship,
    // We want to always be using super up-to-date market prices for the trader.
    maxAge: const Duration(seconds: 5),
  );
  await centralCommand.visitLocalShipyard(
    api,
    caches.shipyardPrices,
    caches.transactions,
    caches.agent,
    currentWaypoint,
    ship,
  );

  if (centralCommand.isContractTradingEnabled) {
    await acceptContractsIfNeeded(
      api,
      caches.contracts,
      caches.marketPrices,
      caches.agent,
      caches.ships,
      ship,
    );
  }

  final behaviorState = centralCommand.getBehavior(ship.shipSymbol)!;
  final pastDeal = behaviorState.deal;
  // Regardless of where we are, if we have cargo that isn't part of our deal,
  // try to sell it.
  final result = await handleUnwantedCargoIfNeeded(
    api,
    centralCommand,
    caches,
    ship,
    currentMarket,
    pastDeal?.tradeSymbol,
  );
  if (result.isError) {
    disableWithJobError(ship, centralCommand, result.error);
    return null;
  }
  if (result.shouldReturn) {
    return result.waitTime;
  }

  // We already have a deal, handle it.
  if (pastDeal != null) {
    final waitUntil = await _handleDeal(
      api,
      centralCommand,
      caches,
      pastDeal,
      ship,
      currentMarket,
    );
    return waitUntil;
  }

  // We don't have a current deal, so get a new one:
  // Consider all deals starting at any market within our consideration range.
  final newDeal = await centralCommand.findNextDeal(
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
      why,
    );
    return waitUntil;
  }

  if (newDeal == null) {
    return findBetterLocation('No profitable deals within $_maxJumps jumps '
        'of ${ship.systemSymbol}.');
  }
  if (newDeal.expectedProfitPerSecond <
      centralCommand.expectedCreditsPerSecond(ship)) {
    return findBetterLocation('Deal expected profit per second too low: '
        '${creditsString(newDeal.expectedProfitPerSecond)}/s');
  }

  shipInfo(ship, 'Found deal: ${describeCostedDeal(newDeal)}');
  final state = centralCommand.getBehavior(ship.shipSymbol)!..deal = newDeal;
  centralCommand.setBehavior(ship.shipSymbol, state);
  final waitUntil = await _handleDeal(
    api,
    centralCommand,
    caches,
    newDeal,
    ship,
    currentMarket,
  );
  return waitUntil;
}
