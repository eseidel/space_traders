import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

// This is split out from the main function to allow early returns.
/// Public to allow sharing with contract trader (for now).
Future<Transaction?> purchaseTradeGoodIfPossible(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Ship ship,
  MarketTradeGood marketGood,
  String neededTradeSymbol, {
  required int maxWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
}) async {
  // And its selling at a reasonable price.
  // If the market is above maxWorthwhileUnitPurchasePrice and we don't have any
  // cargo yet then we give up and try again.
  if (marketGood.purchasePrice >= maxWorthwhileUnitPurchasePrice) {
    shipInfo(
      ship,
      '$neededTradeSymbol is too expensive at ${ship.nav.waypointSymbol} '
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
    TradeSymbol.fromJson(neededTradeSymbol)!,
    unitsToPurchase,
  );
  return result;
}

int _unitsToPurchase(
  CostedDeal costedDeal,
  MarketTradeGood good,
  Ship ship,
) {
  // Many market goods trade in batches much smaller than our cargo hold
  // e.g. 10 vs. 120, if we try to buy 120 we'll get an error.
  final marketTradeVolume = good.tradeVolume;
  final unitsToPurchase = min(marketTradeVolume, ship.availableSpace);
  // Some deals have limited size (like contracts) for normal arbitrage deals
  // costedDeal.tradeVolume == ship.cargoSpace.
  return min(unitsToPurchase, costedDeal.tradeVolume);
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

  final unitsToPurchase = _unitsToPurchase(costedDeal, good, ship);
  final transaction = await purchaseTradeGoodIfPossible(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    good,
    dealTradeSymbol,
    maxWorthwhileUnitPurchasePrice: maxPerUnitPrice,
    unitsToPurchase: unitsToPurchase,
  );

  if (transaction != null && ship.cargo.availableSpace > 0) {
    shipInfo(
      ship,
      'Purchased $unitsToPurchase of $dealTradeSymbol, still have '
      '${ship.cargo.availableSpace} units of cargo space looping.',
    );
    return null;
  }

  if (transaction != null) {
    shipInfo(
      ship,
      'Purchased ${transaction.quantity} ${transaction.tradeSymbol} '
      '@ ${transaction.perUnitPrice} (expected '
      '${costedDeal.deal.purchasePrice}) = '
      '${creditsString(transaction.creditChange)}',
    );
    await centralCommand.recordDealTransactions(ship, [transaction]);
  }
  final haveTradeCargo = ship.cargo.countUnits(dealTradeSymbol) > 0;
  if (!haveTradeCargo) {
    // We couldn't buy any cargo, so we're done with this deal.
    shipWarn(
      ship,
      'Unable to purchase $dealTradeSymbol, giving up on this trade.',
    );
    await centralCommand.completeBehavior(ship.symbol);
    return null;
  }

  // Otherwise we've bought what we can here, deliver what we have.
  return beingRouteAndLog(
    api,
    ship,
    caches.systems,
    centralCommand,
    costedDeal.deal.destinationSymbol,
  );
}

Future<DateTime?> _handleArbitrageDealAtDestination(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final haveDealCargo = ship.cargo.countUnits(costedDeal.tradeSymbol) > 0;
  if (!haveDealCargo) {
    // We don't have any deal cargo, so we must have just gotten a new
    // deal which *ends* here, but we haven't gotten the cargo yet, go get it.
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      costedDeal.deal.sourceSymbol,
    );
  }
  // We're at the destination, sell and clear the deal.
  final transactions = await sellAllCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    currentMarket,
    ship,
  );
  // We don't yet record the completed deal anywhere.
  final completedDeal = costedDeal.byAddingTransactions(transactions);
  shipInfo(
      ship,
      'Expected ${creditsString(completedDeal.expectedProfit)} profit '
      '(${creditsString(completedDeal.expectedProfitPerSecond)}/s), got '
      '${creditsString(completedDeal.actualProfit)} '
      '(${creditsString(completedDeal.actualProfitPerSecond)}/s)');
  await centralCommand.completeBehavior(ship.symbol);
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
    ship,
    contract,
    neededGood!,
  );

  // Delivering the goods counts as completing the behavior, we'll
  // decide next loop if we need to do more.
  await centralCommand.completeBehavior(ship.symbol);

  if (maybeResponse != null) {
    // Update our cargo counts after fulfilling the contract.
    ship.cargo = maybeResponse.cargo;
    // If we've delivered enough, complete the contract.
    if (maybeResponse.contract.goodNeeded(contractGood)!.amountNeeded <= 0) {
      final response = await api.contracts.fulfillContract(contract.id);
      final data = response!.data;
      caches.agent.updateAgent(data.agent);
      await caches.contracts.updateContract(data.contract);
      shipInfo(ship, 'Contract complete!');
      return null;
    }
  }
  return null;
}

Future<DeliverContract200ResponseData?> _deliverContractGoodsIfPossible(
  Api api,
  ContractCache contractCache,
  Ship ship,
  Contract contract,
  ContractDeliverGood goods,
) async {
  final units = ship.countUnits(goods.tradeSymbol);
  if (units < 1) {
    return null;
  }
  // And we have the desired cargo.
  final response = await deliverContract(
    api,
    ship,
    contractCache,
    contract,
    tradeSymbol: goods.tradeSymbol,
    units: units,
  );
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
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      costedDeal.deal.sourceSymbol,
    );
  } else {
    shipInfo(ship, 'Off course in route to deal, resuming route.');
    // We have the cargo we need, so go sell it.
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      costedDeal.deal.destinationSymbol,
    );
  }
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
  if (costedDeal.deal.sourceSymbol == ship.nav.waypointSymbol) {
    return _handleAtSourceWithDeal(
      api,
      centralCommand,
      caches,
      ship,
      currentMarket!,
      costedDeal,
    );
  }
  // If we're at the destination of the deal, sell.
  if (costedDeal.deal.destinationSymbol == ship.nav.waypointSymbol) {
    if (costedDeal.isContractDeal) {
      return _handleContractDealAtDestination(
        api,
        centralCommand,
        caches,
        ship,
        currentMarket!,
        costedDeal,
      );
    }
    return _handleArbitrageDealAtDestination(
      api,
      centralCommand,
      caches,
      ship,
      currentMarket!,
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

/// Accepts contracts for us if needed.
Future<DateTime?> acceptContractsIfNeeded(
  Api api,
  ContractCache contractCache,
  AgentCache agentCache,
  Ship ship,
) async {
  /// Accept logic we run any time contract trading is turned on.
  final contracts = contractCache.activeContracts;
  if (contracts.isEmpty) {
    await negotiateContractAndLog(api, ship);
    // TODO(eseidel): Print expected time and profits of the new contract.
    return null;
  }
  for (final contract in contractCache.unacceptedContracts) {
    await acceptContractAndLog(api, contractCache, agentCache, contract);
  }
  return null;
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

  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);

  // If we're currently at a market, record the prices and refuel.
  final currentMarket =
      await visitLocalMarket(api, caches, currentWaypoint, ship);
  await visitLocalShipyard(api, caches.shipyardPrices, currentWaypoint, ship);

  if (centralCommand.isContractTradingEnabled) {
    await acceptContractsIfNeeded(
      api,
      caches.contracts,
      caches.agent,
      ship,
    );
  }

  final behaviorState = centralCommand.getBehavior(ship.symbol)!;
  final pastDeal = behaviorState.deal;
  final dealCargo = ship.largestCargo(
    where: (i) => i.symbol == pastDeal?.tradeSymbol,
  );
  final nonDealCargo = ship.largestCargo(
    where: (i) => i.symbol != pastDeal?.tradeSymbol,
  );

  /// Regardless of where we are, if we have cargo that isn't part of our deal,
  /// try to sell it.
  if (nonDealCargo != null) {
    if (currentMarket != null) {
      // If we have cargo that isn't part of our deal, sell it.
      bool exceptDealCargo(String symbol) => symbol != dealCargo?.symbol;
      await sellAllCargoAndLog(
        api,
        caches.marketPrices,
        caches.transactions,
        caches.agent,
        currentMarket,
        ship,
        where: exceptDealCargo,
      );
    }

    if (ship.cargo.isNotEmpty) {
      shipInfo(
        ship,
        'Cargo hold still not empty, finding '
        'market to sell ${nonDealCargo.symbol}.',
      );
      final market = await nearbyMarketWhichTrades(
        caches.systems,
        caches.waypoints,
        caches.markets,
        currentWaypoint,
        nonDealCargo.symbol,
      );
      if (market == null) {
        // We can't sell this cargo anywhere so give up?
        await centralCommand.disableBehaviorForShip(
          ship,
          Behavior.trader,
          'No market for ${nonDealCargo.symbol}.',
          const Duration(hours: 1),
        );
        return null;
      }
      return beingRouteAndLog(
        api,
        ship,
        caches.systems,
        centralCommand,
        market.symbol,
      );
    }
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

  // TODO(eseidel): make maxJumps bigger (and cache MarketScan if needed).
  const maxJumps = 5;

  // We don't have a current deal, so get a new one:
  // Consider all deals starting at any market within our consideration range.
  final newDeal = await centralCommand.findNextDeal(
    caches.agent,
    caches.contracts,
    caches.marketPrices,
    caches.systems,
    caches.waypoints,
    caches.markets,
    ship,
    maxJumps: maxJumps,
    maxTotalOutlay: caches.agent.agent.credits,
    availableSpace: ship.availableSpace,
  );

  if (newDeal == null) {
    // Instead just fly to some nearby system and explore?
    await centralCommand.disableBehaviorForShip(
      ship,
      Behavior.trader,
      'No profitable deals within $maxJumps jumps of ${ship.nav.systemSymbol}.',
      const Duration(minutes: 20),
    );
    return null;
  }

  shipInfo(ship, 'Found deal: ${describeCostedDeal(newDeal)}');
  final state = centralCommand.getBehavior(ship.symbol)!..deal = newDeal;
  await centralCommand.setBehavior(ship.symbol, state);
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
