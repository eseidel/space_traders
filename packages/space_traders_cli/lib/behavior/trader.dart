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
import 'package:space_traders_cli/waypoint_cache.dart';

/// Returns the best deal for the given ship within one jump of it's
/// current location.
Future<Deal?> findBestDealWithinOneJump(
  PriceData priceData,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache, {
  int minimumProfitPer = 0,
}) async {
  // Should this start at HQ rather than the current ship location?
  final connectedSystems =
      waypointCache.connectedSystems(ship.nav.systemSymbol);
  final markets = await connectedSystems
      .asyncExpand((s) => marketCache.marketsInSystem(s.symbol))
      .toList();
  return findBestDealAcrossMarkets(
    priceData,
    ship,
    waypointCache,
    marketCache,
    markets,
    minimumProfitPer: minimumProfitPer,
  );
}

// We want to write a O(N) deal-finding algorithm.
// Which takes in N markets.  And walks the markets for all goods they trade.
// Collects the best P prices for each good as half-deals.
// It then walks all half-deals and finds deals with maximum profit.
// It also could use a cost function for the distance between markets, in
// both time and fuel.  Time cost could be ignored for now, but later
// used as opportunity cost.

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
      final buy = _BuyOpp(
        marketSymbol: market.symbol,
        tradeSymbol: tradeSymbol.value,
        price: estimatePurchasePrice(_priceData, market, tradeSymbol.value)!,
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
  });

  /// The deal being considered.
  Deal deal;

  /// The units of fuel to travel between the two markets.
  int fuelCost;

  /// The number of units of cargo to trade.
  int tradeVolume;

  /// The time in seconds to travel between the two markets.
  int time;

  /// The total upfront cost of the deal, including fuel.
  int get totalOutlay => deal.purchasePrice * tradeVolume + fuelCost;

  /// The total profit of the deal, including fuel.
  int get profit => deal.profit * tradeVolume - fuelCost;

  /// The profit per second of the deal.
  int get profitPerSecond => profit ~/ time;
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
      '$coloredProfitString $timeString ${costedDeal.totalOutlay}c';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(SystemsCache systemsCache, Deal deal, int cargoSize) {
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
      shipSpeed: 30, // Command ship speed.
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
}) async {
  final start = await waypointCache.waypoint(ship.nav.waypointSymbol);
  final markets = await systemSymbolsInJumpRadius(
    waypointCache: waypointCache,
    startSystem: start.systemSymbol,
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

  final costedDeals =
      deals.map((d) => costOutDeal(systemsCache, d, 60)).toList();

  if (costedDeals.isEmpty) {
    logger.info('No deals found.');
    return null;
  }
  final affordable =
      costedDeals.where((d) => d.totalOutlay < maxOutlay).toList();
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

/// Returns the best deal for the given ship across the given set of markets.
Future<Deal?> findBestDealAcrossMarkets(
  PriceData priceData,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  List<Market> markets, {
  int minimumProfitPer = 0,
}) async {
  shipInfo(ship, 'Considering deals across ${markets.length} markets');
  final potentialDeals = markets.map((m) async {
    return findBestDealFromWaypoint(
      priceData,
      ship,
      await waypointCache.waypoint(m.symbol),
      markets,
      minimumProfitPer: minimumProfitPer,
    );
  });
  final maybeDeals = await Future.wait(potentialDeals);
  final deals = maybeDeals.whereType<Deal>().toList();
  if (deals.isEmpty) {
    return null;
  }

  // TODO(eseidel): Need to consider time and fuel costs, for the route.
  // Also need to consider if we can afford the upfront cost of the cargo.
  // Deals which don't start at our current location, also have time and fuel
  // to get to the first waypoint.
  return deals.reduce((a, b) => a.profit > b.profit ? a : b);
}

/// One loop of the trading logic
Future<DateTime?> advanceArbitrageTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  BehaviorManager behaviorManager,
) async {
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    waypointCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }

  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  final currentMarket =
      await marketCache.marketForSymbol(currentWaypoint.symbol);
  // We are at a marketplace, so we can trade.
  // We can also end up here if we're at a waypoint, but it has no market
  // so we need to guard this check.
  if (currentMarket != null) {
    await dockIfNeeded(api, ship);
    await refuelIfNeededAndLog(api, priceData, agent, ship);
    await recordMarketData(priceData, currentMarket);
    // Sell any cargo we can and update our ship's cargo.
    ship.cargo = await sellCargoAndLog(api, priceData, ship);
  }

  // Currently limiting search to markets in the current system.
  const minimumProfit = 500;

  // Consider all deals starting at any market within our consideration range.
  final deal = await findBestDealWithinOneJump(
    priceData,
    ship,
    waypointCache,
    marketCache,
    minimumProfitPer: minimumProfit,
  );
  if (deal == null) {
    await behaviorManager.disableBehavior(ship, Behavior.arbitrageTrader);
    shipInfo(
      ship,
      'No deals >${creditsString(minimumProfit)} '
      'profit, disabling trader behavior.',
    );
    return null;
  }
  shipInfo(ship, 'Found deal: ${describeDeal(deal)}');

  // TODO(eseidel): Save the deal we found so we don't have to recompute it.

  if (deal.sourceSymbol != currentWaypoint.symbol) {
    // We're not at the source, so navigate there.
    return beingRouteAndLog(
      api,
      ship,
      waypointCache,
      behaviorManager,
      deal.sourceSymbol,
    );
  }

  // Otherwise, our deal starts here, so we can buy cargo and go!
  logDeal(ship, deal);
  await purchaseCargoAndLog(
    api,
    priceData,
    ship,
    deal.tradeSymbol.value,
    ship.availableSpace,
  );

  return beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    deal.sourceSymbol,
  );
}
