import 'dart:math';

import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/behavior/navigation.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

// This is split out from the main function to allow early returns.
Future<SellCargo201ResponseData?> _purchaseTradeGoodIfPossible(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Ship ship,
  MarketTradeGood marketGood,
  String neededTradeSymbol, {
  required int maximumWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
}) async {
  // And its selling at a reasonable price.
  if (marketGood.purchasePrice >= maximumWorthwhileUnitPurchasePrice) {
    shipInfo(
      ship,
      '$neededTradeSymbol is too expensive at ${ship.nav.waypointSymbol} '
      'needed < $maximumWorthwhileUnitPurchasePrice, '
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
  // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
  // Buy a full stock of contract goal.
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

Future<DateTime?> _handleAtSourceWithDeal(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship,
  Market currentMarket,
  CostedDeal costedDeal,
) async {
  final dealTradeSymbol = costedDeal.tradeSymbol;
  final good =
      currentMarket.tradeGoods.firstWhere((g) => g.symbol == dealTradeSymbol);

  final maximumPerUnitPrice = costedDeal.maxPurchaseUnitPrice;

  // If the market is above maximumPerUnitPrice and we don't have any cargo
  // yet then we give up and try again.
  // It also allows us repeatedly buy smaller batches of cargo until our
  // hold is full or the price rises above profitability.
  final tradeVolume = good.tradeVolume;
  final unitsToPurchase = min(tradeVolume, ship.availableSpace);

  final maybeResult = await _purchaseTradeGoodIfPossible(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    ship,
    good,
    dealTradeSymbol,
    maximumWorthwhileUnitPurchasePrice: maximumPerUnitPrice,
    unitsToPurchase: unitsToPurchase,
  );

  if (maybeResult != null && ship.cargo.availableSpace > 0) {
    shipInfo(
      ship,
      'Purchased $unitsToPurchase of $dealTradeSymbol, still have '
      '${ship.cargo.availableSpace} units of cargo space looping.',
    );
    return null;
  }

  if (maybeResult != null) {
    final transaction = maybeResult.transaction;
    shipInfo(
      ship,
      'Purchased ${transaction.units} ${transaction.tradeSymbol} '
      '@ ${transaction.pricePerUnit} (expected '
      '${costedDeal.deal.purchasePrice})  = ${transaction.totalPrice}',
    );
    final behaviorState = centralCommand.getBehavior(ship.symbol)!;
    final newTransactions = costedDeal.transactions.toList()..add(transaction);
    behaviorState.deal = costedDeal.copyWith(transactions: newTransactions);
    await centralCommand.setBehavior(ship.symbol, behaviorState);
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

Future<DateTime?> _handleAtDestinationWithDeal(
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
  await sellAllCargoAndLog(
    api,
    caches.marketPrices,
    caches.transactions,
    caches.agent,
    currentMarket,
    ship,
  );
  await centralCommand.completeBehavior(ship.symbol);
  return null;
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
    return _handleAtDestinationWithDeal(
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

/// One loop of the trading logic
Future<DateTime?> advanceArbitrageTrader(
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
      shipInfo(ship, 'Cargo hold still not empty, finding market.');
      final market = await nearbyMarketWhichTrades(
        caches.systems,
        caches.waypoints,
        caches.markets,
        currentWaypoint,
        nonDealCargo.symbol,
      );
      if (market == null) {
        // We can't sell this cargo anywhere so give up?
        await centralCommand.disableBehavior(
          ship,
          Behavior.arbitrageTrader,
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

  // We don't have a current deal, so get a new one:
  // Consider all deals starting at any market within our consideration range.
  final newDeal = await centralCommand.findNextDeal(
    caches.marketPrices,
    caches.systems,
    caches.waypoints,
    caches.markets,
    ship,
    maxJumps: 1,
    maxOutlay: caches.agent.agent.credits,
    availableSpace: ship.availableSpace,
  );

  if (newDeal == null) {
    await centralCommand.disableBehavior(
      ship,
      Behavior.arbitrageTrader,
      'No profitable deals.',
      const Duration(hours: 1),
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
