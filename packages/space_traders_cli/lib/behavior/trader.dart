import 'dart:math';

import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

/// One loop of the trading logic
Future<DateTime?> advanceArbitrageTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return logRemainingTransitTime(ship);
  }
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  final systemWaypoints =
      await waypointCache.waypointsInSystem(currentWaypoint.systemSymbol);
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
  final allMarkets =
      await marketCache.marketsInSystem(currentWaypoint.systemSymbol).toList();
  final currentMarket = lookupMarket(currentWaypoint.symbol, allMarkets);
  await recordMarketData(priceData, currentMarket);
  // Sell any cargo we can.
  ship.cargo = await sellCargoAndLog(api, priceData, ship);
  const minimumProfit = 500;
  final deal = findBestDeal(
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
    // TODO(eseidel): This should not be random, rather should look at the
    // cached price data for the markets and pick one with best deals.
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
  logDeal(ship, deal);
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
