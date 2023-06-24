import 'dart:math';

import 'package:collection/collection.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/trading.dart';

/// Purchase cargo for the deal and start towards destination.
Future<DateTime?> _purchaseCargoAndGo(
  Api api,
  AgentCache agentCache,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  CentralCommand centralCommand,
  Market market,
  Ship ship,
  Deal deal,
) async {
  // This assumes the ship is at the source of the deal.
  assert(deal.sourceSymbol == ship.nav.waypointSymbol, 'Not at source!');
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(
    api,
    marketPrices,
    transactionLog,
    agentCache,
    market,
    ship,
  );

  // Sell any cargo we can and update our ship's cargo.
  if (ship.cargo.isNotEmpty) {
    await sellAllCargoAndLog(
      api,
      marketPrices,
      transactionLog,
      agentCache,
      market,
      ship,
      where: (tradeSymbol) => tradeSymbol != deal.tradeSymbol.value,
    );
  }
  if (ship.cargo.isNotEmpty) {
    shipInfo(
      ship,
      'Ship still has: ${cargoDescription(ship.cargo)}',
    );
  }

  final maybeGood = market.tradeGoods
      .firstWhereOrNull((g) => g.symbol == deal.tradeSymbol.value);
  if (maybeGood == null) {
    throw ArgumentError(
      'No good ${deal.tradeSymbol.value} in ${market.symbol}',
    );
  }

  // We need to figure out what the maximum price is where the deal is still
  // good. (similar to contract trader).  If the market is above that
  // we just give up on this deal and try again.
  // It also allows us repeatedly buy smaller batches of cargo until our
  // hold is full or the price rises above profitability.

  final good = maybeGood;
  final tradeVolume = good.tradeVolume;
  final unitsToPurchase = min(tradeVolume, ship.availableSpace);
  if (unitsToPurchase < ship.availableSpace) {
    shipWarn(
      ship,
      'Buying less than ship can carry! '
      '$unitsToPurchase < ${ship.availableSpace}',
    );
  }

  final maybeResult = await purchaseCargoAndLog(
    api,
    marketPrices,
    transactionLog,
    agentCache,
    ship,
    deal.tradeSymbol,
    unitsToPurchase,
  );
  if (maybeResult == null) {
    // We couldn't buy any cargo, so we're done.
    await centralCommand.disableBehavior(ship, Behavior.arbitrageTrader);
    shipInfo(
      ship,
      'Failed to buy cargo, disabling trader behavior.',
    );
    return null;
  }
  final result = maybeResult;
  final transaction = result.transaction;
  shipInfo(
    ship,
    'Purchased ${transaction.units} ${transaction.tradeSymbol} '
    '@ ${transaction.pricePerUnit} (expected ${deal.purchasePrice}) '
    ' = ${transaction.totalPrice}',
  );
  final behaviorState = centralCommand.getBehavior(ship.symbol)!;
  behaviorState.deal!.actualPurchasePrice = result.transaction.pricePerUnit;
  await centralCommand.setBehavior(ship.symbol, behaviorState);

  return beingRouteAndLog(
    api,
    ship,
    systemsCache,
    centralCommand,
    deal.destinationSymbol,
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
  Market? currentMarket;

  // If we're currently at a market, record the prices and refuel.
  if (currentWaypoint.hasMarketplace) {
    await dockIfNeeded(api, ship);
    currentMarket = await recordMarketDataIfNeededAndLog(
      caches.marketPrices,
      caches.markets,
      ship,
      currentWaypoint.symbol,
    );
    await refuelIfNeededAndLog(
      api,
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      currentMarket,
      ship,
    );
  }

  final behaviorState = centralCommand.getBehavior(ship.symbol)!;
  final pastDeal = behaviorState.deal;

  final pastDealTradeSymbol = pastDeal?.deal.tradeSymbol.value;
  final dealCargo = ship.largestCargo(
    where: (i) => i.symbol == pastDealTradeSymbol,
  );
  final nonDealCargo = ship.largestCargo(
    where: (i) => i.symbol != pastDealTradeSymbol,
  );
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
        // We can't sell this cargo anywhere, so we're done.
        await centralCommand.disableBehavior(ship, Behavior.arbitrageTrader);
        shipInfo(
          ship,
          'No market for ${nonDealCargo.symbol}, disabling trader behavior.',
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

  if (pastDeal != null) {
    // If we have a deal
    // If we're at the source (because we had to travel there) buy the cargo.
    if (pastDeal.deal.sourceSymbol == ship.nav.waypointSymbol) {
      // We're at the source, buy and start the route.
      return _purchaseCargoAndGo(
        api,
        caches.agent,
        caches.systems,
        caches.waypoints,
        caches.marketPrices,
        caches.transactions,
        centralCommand,
        currentMarket!,
        ship,
        pastDeal.deal,
      );
    }

    // If we're at the destination of the deal, sell.
    if (pastDeal.deal.destinationSymbol == ship.nav.waypointSymbol) {
      // We're at the destination, sell and clear the deal.
      await sellAllCargoAndLog(
        api,
        caches.marketPrices,
        caches.transactions,
        caches.agent,
        currentMarket!,
        ship,
      );
      await centralCommand.completeBehavior(ship.symbol);
      return null;
    }

    shipInfo(ship, 'Off course in route to deal, resuming route.');
    return beingRouteAndLog(
      api,
      ship,
      caches.systems,
      centralCommand,
      pastDeal.deal.destinationSymbol,
    );
  }

  // We don't have a current deal, so get a new one!A

  // Find a new deal!
  const maxJumps = 1;
  final maxOutlay = caches.agent.agent.credits;

  // Consider all deals starting at any market within our consideration range.
  final deal = await findDealFor(
    caches.marketPrices,
    caches.systems,
    caches.waypoints,
    caches.markets,
    ship,
    maxJumps: maxJumps,
    maxOutlay: maxOutlay,
    availableSpace: ship.availableSpace,
  );

  if (deal == null) {
    await centralCommand.disableBehavior(ship, Behavior.arbitrageTrader);
    shipInfo(
      ship,
      'No profitable deals, disabling trader behavior.',
    );
    return null;
  }

  shipInfo(ship, 'Found deal: ${describeCostedDeal(deal)}');
  final state = centralCommand.getBehavior(ship.symbol)!..deal = deal;
  await centralCommand.setBehavior(ship.symbol, state);

  if (deal.deal.sourceSymbol == currentWaypoint.symbol) {
    // Our deal starts here, so we can buy cargo and go!
    logDeal(ship, deal.deal);
    return _purchaseCargoAndGo(
      api,
      caches.agent,
      caches.systems,
      caches.waypoints,
      caches.marketPrices,
      caches.transactions,
      centralCommand,
      currentMarket!,
      ship,
      deal.deal,
    );
  }

  // Otherwise we're not at the source, so first navigate there.
  return beingRouteAndLog(
    api,
    ship,
    caches.systems,
    centralCommand,
    deal.deal.sourceSymbol,
  );
}
