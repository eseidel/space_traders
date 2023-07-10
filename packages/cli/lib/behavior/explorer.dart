import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';

bool _isMissingChartOrRecentPriceData(
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Waypoint waypoint,
) {
  return waypoint.chart == null ||
      _isMissingRecentMarketData(marketPrices, waypoint) ||
      _isMissingRecentShipyardData(shipyardPrices, waypoint);
}

bool _isMissingRecentMarketData(MarketPrices marketPrices, Waypoint waypoint) {
  return waypoint.hasMarketplace &&
      !marketPrices.hasRecentMarketData(waypoint.symbol);
}

bool _isMissingRecentShipyardData(
  ShipyardPrices shipyardPrices,
  Waypoint waypoint,
) {
  return waypoint.hasShipyard &&
      !shipyardPrices.hasRecentShipyardData(waypoint.symbol);
}

/// Visits the local market if we're at a waypoint with a market.
/// Will return the market if we visited it, otherwise null.
/// Market data will be recorded if needed.
/// Market data only be refreshed if we haven't refreshed in 5 minutes.
Future<Market?> visitLocalMarket(
  Api api,
  Caches caches,
  Waypoint waypoint,
  Ship ship, {
  Duration maxAge = const Duration(minutes: 5),
}) async {
  // If we're currently at a market, record the prices and refuel.
  if (!waypoint.hasMarketplace) {
    return null;
  }
  // This could avoid the dock and market lookup if the caller
  // doesn't need the Market value, we don't need fuel and we have
  // recent market data.
  await dockIfNeeded(api, ship);
  final market = await recordMarketDataIfNeededAndLog(
    caches.marketPrices,
    caches.markets,
    ship,
    waypoint.symbol,
    maxAge: maxAge,
  );
  if (ship.usesFuel) {
    await refuelIfNeededAndLog(
      api,
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      market,
      ship,
    );
  }
  return market;
}

/// One loop of the exploring logic.
Future<DateTime?> advanceExplorer(
  Api api,
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  assert(!ship.isInTransit, 'Ship ${ship.symbol} is in transit');

  final waypoint = await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  // advanceExplorer is only ever called when we're idle at a location, so
  // either it's the first time and we need to set a destination, or we've just
  // completed a loop.  This _isMissingChartOrRecentPriceData is really our
  // check for "did we just do a loop"?  If so, we complete the behavior.
  if (_isMissingChartOrRecentPriceData(
    caches.marketPrices,
    caches.shipyardPrices,
    waypoint,
  )) {
    if (waypoint.chart == null) {
      await chartWaypointAndLog(api, ship);
    }
    await visitLocalMarket(api, caches, waypoint, ship);
    // We might buy a ship if we're at a ship yard.
    await centralCommand.visitLocalShipyard(
      api,
      caches.shipyardPrices,
      caches.agent,
      waypoint,
      ship,
    );
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    await centralCommand.completeBehavior(ship.symbol);
    return null;
  }

  final probeSystems = centralCommand.otherExplorerSystems(ship.symbol).toSet();
  const maxJumpDistance = 100;
  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  await for (final destination in caches.waypoints.waypointsInJumpRadius(
    startSystem: waypoint.systemSymbol,
    maxJumps: maxJumpDistance,
  )) {
    if (probeSystems.contains(destination.systemSymbol)) {
      // We already have a ship in this system, don't route there.
      continue;
    }
    if (_isMissingChartOrRecentPriceData(
      caches.marketPrices,
      caches.shipyardPrices,
      destination,
    )) {
      if (destination.chart == null) {
        shipInfo(
          ship,
          '${destination.symbol} is missing chart, routing.',
        );
      } else if (_isMissingRecentMarketData(
        caches.marketPrices,
        destination,
      )) {
        shipInfo(
          ship,
          '${destination.symbol} is missing recent '
          '(${approximateDuration(defaultMaxAge)}) market data, '
          'routing.',
        );
      } else {
        shipInfo(
          ship,
          '${destination.symbol} is missing recent '
          '(${approximateDuration(defaultMaxAge)}) shipyard data, '
          'routing.',
        );
      }
      return beingRouteAndLog(
        api,
        ship,
        caches.systems,
        caches.systemConnectivity,
        centralCommand,
        destination.symbol,
      );
    }
  }
  // If we get here, we've explored all systems within maxJumpDistance jumps
  // of this system.  We just log an error and sleep.
  await centralCommand.disableBehaviorForShip(
    ship,
    Behavior.explorer,
    'No unexplored systems within $maxJumpDistance jumps of '
    '${waypoint.systemSymbol}.',
    const Duration(hours: 1),
  );
  return null;
}
