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
import 'package:space_traders_cli/queries.dart';

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
