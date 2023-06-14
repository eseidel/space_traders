import 'dart:math';

import 'package:collection/collection.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/route.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

@immutable
class _BuyOpp {
  const _BuyOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
  });
  final String marketSymbol;
  final String tradeSymbol;
  final int price;
}

@immutable
class _SellOpp {
  const _SellOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
  });
  final String marketSymbol;
  final String tradeSymbol;
  final int price;
}

/// Finds deals between markets.
class DealFinder {
  /// Create a new DealFinder.
  DealFinder(PriceData priceData, {this.topLimit = 5}) : _priceData = priceData;
  // _systemsCache = systemsCache,

  final PriceData _priceData;
  // final SystemsCache _systemsCache;
  /// How many deals to keep track of per trade symbol.
  final int topLimit;
  final Map<String, List<_BuyOpp>> _buyOpps = {};
  final Map<String, List<_SellOpp>> _sellOpps = {};

  /// Record potential deals from the given market.
  void visitMarket(Market market) {
    for (final tradeSymbol in market.allTradeSymbols) {
      // See if the price data we have for this trade symbol
      // are in the top/bottom we've seen, if so, record them.
      final buyPrice =
          estimatePurchasePrice(_priceData, market, tradeSymbol.value);
      if (buyPrice == null) {
        // If we don't have buy data we won't have sell data either.
        continue;
      }
      final buy = _BuyOpp(
        marketSymbol: market.symbol,
        tradeSymbol: tradeSymbol.value,
        price: buyPrice,
      );
      final buys = _buyOpps[tradeSymbol.value] ?? [];
      // No clue what it wants me to cascade here?
      // ignore: cascade_invocations
      buys
        ..add(buy)
        ..sort((a, b) => a.price.compareTo(b.price));
      if (buys.length > topLimit) {
        buys.removeLast();
      }
      _buyOpps[tradeSymbol.value] = buys;
      final sell = _SellOpp(
        marketSymbol: market.symbol,
        tradeSymbol: tradeSymbol.value,
        price: estimateSellPrice(_priceData, market, tradeSymbol.value)!,
      );
      final sells = _sellOpps[tradeSymbol.value] ?? [];
      // No clue what it wants me to cascade here?
      // ignore: cascade_invocations
      sells
        ..add(sell)
        ..sort((a, b) => a.price.compareTo(b.price));
      if (sells.length > topLimit) {
        sells.removeLast();
      }
      _sellOpps[tradeSymbol.value] = sells;
    }
  }

  /// Returns all deals found.
  List<Deal> findDeals() {
    final deals = <Deal>[];
    // final fuelPrice = _priceData.medianPurchasePrice(TradeSymbol.FUEL.value);
    for (final tradeSymbol in _buyOpps.keys) {
      final buys = _buyOpps[tradeSymbol]!;
      final sells = _sellOpps[tradeSymbol]!;
      for (final buy in buys) {
        for (final sell in sells) {
          if (buy.marketSymbol == sell.marketSymbol) {
            continue;
          }
          final profit = sell.price - buy.price;
          if (profit <= 0) {
            continue;
          }
          deals.add(
            Deal(
              sourceSymbol: buy.marketSymbol,
              tradeSymbol: TradeSymbol.fromJson(tradeSymbol)!,
              purchasePrice: buy.price,
              destinationSymbol: sell.marketSymbol,
              sellPrice: sell.price,
            ),
          );
        }
      }
    }
    return deals;
  }
}

/// A deal between two markets which considers flight cost and time.
class CostedDeal {
  /// Create a new CostedDeal.
  CostedDeal({
    required this.deal,
    required this.fuelCost,
    required this.tradeVolume,
    required this.time,
    this.actualPurchasePrice,
    this.actualSellPrice,
  });

  /// Create a CostedDeal from JSON.
  factory CostedDeal.fromJson(Map<String, dynamic> json) => CostedDeal(
        deal: Deal.fromJson(json['deal'] as Map<String, dynamic>),
        fuelCost: json['fuelCost'] as int,
        tradeVolume: json['tradeVolume'] as int,
        time: json['time'] as int,
        actualPurchasePrice: json['actualPurchasePrice'] as int?,
        actualSellPrice: json['actualSellPrice'] as int?,
      );

  /// The deal being considered.
  Deal deal;

  /// The units of fuel to travel between the two markets.
  int fuelCost;

  /// The number of units of cargo to trade.
  int tradeVolume;

  /// The time in seconds to travel between the two markets.
  int time;

  /// The actual purchase price of the deal.
  int? actualPurchasePrice;

  /// The actual sell price of the deal.
  int? actualSellPrice;

  /// The expected cost of goods sold, not including fuel.
  int get expectedCostOfGoodsSold => deal.purchasePrice * tradeVolume;

  /// The expected non-goods expenses of the deal, including fuel.
  int get expectedOperationalExpenses => fuelCost;

  /// The total upfront cost of the deal, including fuel.
  int get expectedCosts => deal.purchasePrice * tradeVolume + fuelCost;

  /// The total income of the deal, including fuel.
  int get expectedRevenue => deal.sellPrice * tradeVolume;

  /// Max we would spend per unit and still expect to break even.
  int get maxPurchasePrice =>
      (expectedRevenue - expectedOperationalExpenses) ~/ tradeVolume;

  /// The total profit of the deal, including fuel.
  int get profit => deal.profit * tradeVolume - fuelCost;

  /// The profit per second of the deal.
  int get profitPerSecond => profit ~/ time;

  /// Convert this CostedDeal to JSON.
  Map<String, dynamic> toJson() => {
        'deal': deal.toJson(),
        'fuelCost': fuelCost,
        'tradeVolume': tradeVolume,
        'time': time,
        'actualPurchasePrice': actualPurchasePrice,
        'actualSellPrice': actualSellPrice,
      };
}

/// Returns a string describing the given CostedDeal
String describeCostedDeal(CostedDeal costedDeal) {
  final deal = costedDeal.deal;
  final sign = deal.profit > 0 ? '+' : '';
  final profitPercent = (deal.profit / deal.purchasePrice) * 100;
  final profitCreditsString = '$sign${creditsString(deal.profit)}'.padLeft(8);
  final profitPercentString =
      '(${profitPercent.toStringAsFixed(0)}%)'.padLeft(5);
  final profitString = '$profitCreditsString $profitPercentString';
  final coloredProfitString = deal.profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  final timeString = '${costedDeal.time}s ${costedDeal.profitPerSecond}c/s';
  return '${deal.tradeSymbol.value.padRight(25)} '
      ' ${deal.sourceSymbol} ${creditsString(deal.purchasePrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol} ${creditsString(deal.sellPrice).padLeft(8)} '
      '$coloredProfitString $timeString ${costedDeal.expectedCosts}c';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  SystemsCache systemsCache,
  Deal deal, {
  required int cargoSize,
  required int shipSpeed,
}) {
  final source = systemsCache.waypointFromSymbol(deal.sourceSymbol);
  final destination = systemsCache.waypointFromSymbol(deal.destinationSymbol);
  return CostedDeal(
    deal: deal,
    fuelCost: fuelUsedBetween(
      systemsCache,
      source,
      destination,
    ),
    time: flightTimeBetween(
      systemsCache,
      source,
      destination,
      flightMode: ShipNavFlightMode.CRUISE,
      shipSpeed: shipSpeed,
    ),
    tradeVolume: cargoSize,
  );
}

/// Returns the best deal for the given ship within [maxJumps] of it's
/// current location.
Future<CostedDeal?> findDealFor(
  PriceData priceData,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Ship ship, {
  required int maxJumps,
  required int maxOutlay,
  required int availableSpace,
}) async {
  final start = ship.nav.waypointSymbol;
  final markets = await systemSymbolsInJumpRadius(
    systemsCache: systemsCache,
    startSystem: start,
    maxJumps: maxJumps,
  )
      .asyncExpand(
        (record) => marketCache.marketsInSystem(record.$1),
      )
      .toList();
  final finder = DealFinder(priceData);
  for (final market in markets) {
    finder.visitMarket(market);
  }
  final deals = finder.findDeals();

  final costedDeals = deals
      .map(
        (d) => costOutDeal(
          systemsCache,
          d,
          cargoSize: availableSpace,
          shipSpeed: ship.engine.speed,
        ),
      )
      .toList();

  if (costedDeals.isEmpty) {
    logger.info('No deals found.');
    return null;
  }
  final affordable =
      costedDeals.where((d) => d.expectedCosts < maxOutlay).toList();
  if (affordable.isEmpty) {
    logger.info('No deals found under $maxOutlay credits.');
    return null;
  }
  final sortedDeals = affordable
      .sorted((a, b) => a.profitPerSecond.compareTo(b.profitPerSecond));

  logger.detail('Considering deals:');
  for (final deal in sortedDeals) {
    logger.detail(describeCostedDeal(deal));
  }
  return sortedDeals.last;
}

/// Returns the fuel cost to travel between two waypoints.
/// This assumes the two waypoints are either within the same system
/// or are connected by jump gates.
int fuelUsedBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b,
) {
  if (a.systemSymbol == b.systemSymbol) {
    return fuelUsedWithinSystem(a, b);
  }
  // a -> jump gate
  // jump N times
// jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  return fuelUsedWithinSystem(a, aJumpGate) +
      fuelUsedWithinSystem(bJumpGate, b);
}

/// Returns flight time in seconds between two waypoints.
int flightTimeBetween(
  SystemsCache systemsCache,
  SystemWaypoint a,
  SystemWaypoint b, {
  required ShipNavFlightMode flightMode,
  required int shipSpeed,
}) {
  if (a.systemSymbol == b.systemSymbol) {
    return flightTimeWithinSystemInSeconds(
      a,
      b,
      flightMode: flightMode,
      shipSpeed: shipSpeed,
    );
  }
  // a -> jump gate
  // jump N times
  // jump gate -> b
  final aJumpGate = systemsCache.jumpGateWaypointForSystem(a.systemSymbol);
  if (aJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${a.systemSymbol}',
    );
  }
  // Ignoring if there is actually a path between the jump gates.
  final bJumpGate = systemsCache.jumpGateWaypointForSystem(b.systemSymbol);
  if (bJumpGate == null) {
    throw ArgumentError(
      'No jump gate for ${b.systemSymbol}',
    );
  }
  // Assuming a and b are connected systems!
  return flightTimeWithinSystemInSeconds(
        a,
        aJumpGate,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      ) +
      flightTimeWithinSystemInSeconds(
        bJumpGate,
        b,
        flightMode: flightMode,
        shipSpeed: shipSpeed,
      );
}

/// Purchase cargo for the deal and start towards destination.
Future<DateTime?> _purchaseCargoAndGo(
  Api api,
  Agent agent,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  PriceData priceData,
  TransactionLog transactionLog,
  BehaviorManager behaviorManager,
  Market market,
  Ship ship,
  Deal deal,
) async {
  // This assumes the ship is at the source of the deal.
  assert(deal.sourceSymbol == ship.nav.waypointSymbol, 'Not at source!');
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(
    api,
    priceData,
    transactionLog,
    agent,
    market,
    ship,
  );

  // Sell any cargo we can and update our ship's cargo.
  if (ship.cargo.isNotEmpty) {
    await sellAllCargoAndLog(
      api,
      priceData,
      transactionLog,
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
    priceData,
    transactionLog,
    ship,
    deal.tradeSymbol.value,
    unitsToPurchase,
  );
  if (maybeResult == null) {
    // We couldn't buy any cargo, so we're done.
    await behaviorManager.disableBehavior(ship, Behavior.arbitrageTrader);
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
  final behaviorState = await behaviorManager.getBehavior(ship);
  behaviorState.deal!.actualPurchasePrice = result.transaction.pricePerUnit;
  await behaviorManager.setBehavior(ship.symbol, behaviorState);

  return beingRouteAndLog(
    api,
    ship,
    systemsCache,
    behaviorManager,
    deal.destinationSymbol,
  );
}

/// One loop of the trading logic
Future<DateTime?> advanceArbitrageTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  TransactionLog transactionLog,
  BehaviorManager behaviorManager,
) async {
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    systemsCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }

  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  Market? currentMarket;

  // If we're currently at a market, record the prices and refuel.
  if (currentWaypoint.hasMarketplace) {
    await dockIfNeeded(api, ship);
    currentMarket = await recordMarketDataIfNeededAndLog(
      priceData,
      marketCache,
      ship,
      currentWaypoint.symbol,
    );
    await refuelIfNeededAndLog(
      api,
      priceData,
      transactionLog,
      agent,
      currentMarket,
      ship,
    );
  }

  final behaviorState = await behaviorManager.getBehavior(ship);
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
        priceData,
        transactionLog,
        ship,
        where: exceptDealCargo,
      );
    }

    if (ship.cargo.isNotEmpty) {
      shipInfo(ship, 'Cargo hold still not empty, finding market.');
      final market = await nearbyMarketWhichTrades(
        systemsCache,
        waypointCache,
        marketCache,
        currentWaypoint,
        nonDealCargo.symbol,
      );
      if (market == null) {
        // We can't sell this cargo anywhere, so we're done.
        await behaviorManager.disableBehavior(ship, Behavior.arbitrageTrader);
        shipInfo(
          ship,
          'No market for ${nonDealCargo.symbol}, disabling trader behavior.',
        );
        return null;
      }
      return beingRouteAndLog(
        api,
        ship,
        systemsCache,
        behaviorManager,
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
        agent,
        systemsCache,
        waypointCache,
        priceData,
        transactionLog,
        behaviorManager,
        currentMarket!,
        ship,
        pastDeal.deal,
      );
    }

    // If we're at the destination of the deal, sell.
    if (pastDeal.deal.destinationSymbol == ship.nav.waypointSymbol) {
      // We're at the destination, sell and clear the deal.
      await sellAllCargoAndLog(api, priceData, transactionLog, ship);
      await behaviorManager.completeBehavior(ship.symbol);
      return null;
    }

    shipInfo(ship, 'Off course in route to deal, resuming route.');
    return beingRouteAndLog(
      api,
      ship,
      systemsCache,
      behaviorManager,
      pastDeal.deal.destinationSymbol,
    );
  }

  // We don't have a current deal, so get a new one!A

  // Find a new deal!
  const maxJumps = 1;
  final maxOutlay = agent.credits;

  // Consider all deals starting at any market within our consideration range.
  final deal = await findDealFor(
    priceData,
    systemsCache,
    waypointCache,
    marketCache,
    ship,
    maxJumps: maxJumps,
    maxOutlay: maxOutlay,
    availableSpace: ship.availableSpace,
  );

  if (deal == null) {
    await behaviorManager.disableBehavior(ship, Behavior.arbitrageTrader);
    shipInfo(
      ship,
      'No profitable deals, disabling trader behavior.',
    );
    return null;
  }

  shipInfo(ship, 'Found deal: ${describeCostedDeal(deal)}');
  final state = await behaviorManager.getBehavior(ship);
  state.deal = deal;
  await behaviorManager.setBehavior(ship.symbol, state);

  if (deal.deal.sourceSymbol == currentWaypoint.symbol) {
    // Our deal starts here, so we can buy cargo and go!
    logDeal(ship, deal.deal);
    return _purchaseCargoAndGo(
      api,
      agent,
      systemsCache,
      waypointCache,
      priceData,
      transactionLog,
      behaviorManager,
      currentMarket!,
      ship,
      deal.deal,
    );
  }

  // Otherwise we're not at the source, so first navigate there.
  return beingRouteAndLog(
    api,
    ship,
    systemsCache,
    behaviorManager,
    deal.deal.sourceSymbol,
  );
}
