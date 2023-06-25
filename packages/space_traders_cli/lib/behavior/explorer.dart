import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/printing.dart';

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

Future<Waypoint?> _nearestWaypointNeedingExploration(
  WaypointCache waypointCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship,
) async {
  final systemWaypoints =
      await waypointCache.waypointsInSystem(ship.nav.systemSymbol);
  for (final waypoint in systemWaypoints) {
    if (_isMissingChartOrRecentPriceData(
      marketPrices,
      shipyardPrices,
      waypoint,
    )) {
      return waypoint;
    }
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

  // Check our current waypoint.  If it's not charted or doesn't have current
  // market data, chart it and/or record market data.
  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  // We currently never route to shipyards, but we will record their data if
  // we happen to be there.
  if (_isMissingChartOrRecentPriceData(
    caches.marketPrices,
    caches.shipyardPrices,
    currentWaypoint,
  )) {
    if (currentWaypoint.chart == null) {
      await chartWaypointAndLog(api, ship);
    }
    if (currentWaypoint.hasMarketplace) {
      final market = await recordMarketDataIfNeededAndLog(
        caches.marketPrices,
        caches.markets,
        ship,
        currentWaypoint.symbol,
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
    }
    if (currentWaypoint.hasShipyard) {
      // Every time we're at a shipyard and can afford a ship, we should
      // buy one.  Probably ore hounds at first, then probes?
      final shipyard = await getShipyard(api, currentWaypoint);
      await recordShipyardDataAndLog(caches.shipyardPrices, shipyard, ship);
    }
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    await centralCommand.completeBehavior(ship.symbol);
    return null;
  }

  // Check the current system waypoints.
  // If any are not explored, or have a market but don't have recent market
  // data, got there.
  // TODO(eseidel): This navigation logic should use beginRouteAndLog.
  final nearest = await _nearestWaypointNeedingExploration(
    caches.waypoints,
    caches.marketPrices,
    caches.shipyardPrices,
    ship,
  );
  if (nearest != null) {
    shipInfo(
      ship,
      'Exploring ${nearest.symbol} in ${nearest.systemSymbol}',
    );
    return navigateToLocalWaypointAndLog(api, ship, nearest.toSystemWaypoint());
  }

  // If at a jump gate, go to a nearby system with unexplored waypoints or
  // missing market data.
  if (currentWaypoint.isJumpGate) {
    // TODO(eseidel): I believe this is the source of requests.
    // final myShips = await allMyShips(api).toList();
    // final probeSystems =
    //     myShips.where((s) => s.isProbe)
    //     .map((s) => s.nav.systemSymbol).toSet();
    const maxJumpDistance = 100;
    // Walk waypoints as far out as we can see until we find one missing
    // a chart or market data and route to there.
    await for (final destination in caches.waypoints.waypointsInJumpRadius(
      startSystem: currentWaypoint.systemSymbol,
      maxJumps: maxJumpDistance,
    )) {
      // Crude logic to spread our explorers out.
      // This doesn't actually work if they're jumping multiple times, it's just
      // preventing the probe from *routing* to the intermediate place the
      // other probes are in.
      // We need to check the probe destinations stored in behavior state?
      // if (probeSystems.contains(destination.systemSymbol)) {
      //   // We already have a ship in this system, don't route there.
      //   continue;
      // }
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
          centralCommand,
          destination.symbol,
        );
      }
    }
    // If we get here, we've explored all systems within maxJumpDistance jumps
    // of this system.  We just log an error and sleep.
    await centralCommand.disableBehavior(
      ship,
      Behavior.explorer,
      'No unexplored systems within $maxJumpDistance jumps of '
      '${currentWaypoint.systemSymbol}.',
      const Duration(hours: 1),
    );
    return null;
  }

  // Otherwise, go to a jump gate.
  final jumpGate =
      caches.systems.jumpGateWaypointForSystem(ship.nav.systemSymbol);
  if (jumpGate == null) {
    throw UnimplementedError('No jump gates in ${ship.nav.waypointSymbol}');
  }
  return navigateToLocalWaypointAndLog(api, ship, jumpGate);
}
