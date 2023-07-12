import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';

bool _isMissingChartOrRecentPriceData(
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.chart == null ||
      _isMissingRecentMarketData(marketPrices, waypoint, maxAge: maxAge) ||
      _isMissingRecentShipyardData(shipyardPrices, waypoint, maxAge: maxAge);
}

bool _isMissingRecentMarketData(
  MarketPrices marketPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.hasMarketplace &&
      !marketPrices.hasRecentMarketData(waypoint.symbol, maxAge: maxAge);
}

bool _isMissingRecentShipyardData(
  ShipyardPrices shipyardPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.hasShipyard &&
      !shipyardPrices.hasRecentShipyardData(waypoint.symbol, maxAge: maxAge);
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

Future<Waypoint?> _findNewWaypointToExplore(
  WaypointCache waypointCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship, {
  required String startSystem,
  required int maxJumpDistance,
  required bool Function(String systemSymbol) filter,
  required Duration maxAge,
}) async {
  await for (final destination in waypointCache.waypointsInJumpRadius(
    startSystem: startSystem,
    maxJumps: maxJumpDistance,
  )) {
    if (!filter(destination.symbol)) {
      // We already have a ship in this system, don't route there.
      continue;
    }
    if (!_isMissingChartOrRecentPriceData(
      marketPrices,
      shipyardPrices,
      destination,
      maxAge: maxAge,
    )) {
      continue;
    }
    if (destination.chart == null) {
      shipInfo(
        ship,
        '${destination.symbol} is missing chart, routing.',
      );
    } else if (_isMissingRecentMarketData(
      marketPrices,
      destination,
      maxAge: maxAge,
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
    return destination;
  }
  return null;
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

  final maxAge = centralCommand.maxAgeForExplorerData;
  final waypoint = await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  // advanceExplorer is only ever called when we're idle at a location, so
  // either it's the first time and we need to set a destination, or we've just
  // completed a loop.  This _isMissingChartOrRecentPriceData is really our
  // check for "did we just do a loop"?  If so, we complete the behavior.
  if (_isMissingChartOrRecentPriceData(
    caches.marketPrices,
    caches.shipyardPrices,
    waypoint,
    maxAge: maxAge,
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
  // TODO(eseidel): maxWaypoints rather than max jumps.
  const maxJumpDistance = 20;
  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  // TODO(eseidel): This can take a very long time on a cold cache.
  final startTime = getNow();
  final destination = await _findNewWaypointToExplore(
    caches.waypoints,
    caches.marketPrices,
    caches.shipyardPrices,
    ship,
    startSystem: ship.nav.systemSymbol,
    maxJumpDistance: maxJumpDistance,
    filter: (String systemSymbol) => !probeSystems.contains(systemSymbol),
    maxAge: maxAge,
  );
  final endTime = getNow();
  final elapsed = endTime.difference(startTime);
  if (elapsed > const Duration(seconds: 5)) {
    shipErr(
      ship,
      'Took ${approximateDuration(elapsed)} to find next system to explore.',
    );
  }
  if (destination != null) {
    return beingNewRouteAndLog(
      api,
      ship,
      caches.systems,
      caches.systemConnectivity,
      caches.jumps,
      centralCommand,
      destination.symbol,
    );
  }
  // If we get here, we've explored all systems within maxJumpDistance jumps
  // of this system.
  shipWarn(
    ship,
    'No unexplored systems within $maxJumpDistance jumps of '
    '${waypoint.systemSymbol}.',
  );
  final newMaxAge = centralCommand.shortenMaxAgeForExplorerData();
  shipWarn(
    ship,
    'Shortened maxAge to ${approximateDuration(newMaxAge)} and resuming.',
  );
  return null;
}
