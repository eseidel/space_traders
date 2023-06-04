import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

bool _isMissingChartOrRecentMarketData(PriceData priceData, Waypoint waypoint) {
  return waypoint.chart == null ||
      waypoint.hasMarketplace &&
          !priceData.hasRecentMarketData(
            waypoint.symbol,
          );
}

/// One loop of the exploring logic.
Future<DateTime?> advanceExporer(
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
  // Check our current waypoint.  If it's not charted or doesn't have current
  // market data, chart it and/or record market data.
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  if (_isMissingChartOrRecentMarketData(priceData, currentWaypoint)) {
    if (currentWaypoint.chart == null) {
      await chartWaypointAndLog(api, ship);
      return null;
    }
    if (currentWaypoint.hasMarketplace &&
        !priceData.hasRecentMarketData(
          currentWaypoint.symbol,
        )) {
      final market = await marketCache.marketForSymbol(currentWaypoint.symbol);
      await recordMarketDataAndLog(priceData, market!, ship);
      return null;
    }
    // Explore behavior never changes, but it's still the corect thing to
    // reset our state after completing on loop of "explore".
    await behaviorManager.completeBehavior(ship.symbol);
  }

  // Check the current system waypoints.
  // If any are not explored, or have a market but don't have recent market
  // data, got there.
  // TODO(eseidel): This navigation logic should use beginRouteAndLog.
  final systemWaypoints =
      await waypointCache.waypointsInSystem(ship.nav.systemSymbol);
  for (final waypoint in systemWaypoints) {
    if (_isMissingChartOrRecentMarketData(priceData, waypoint)) {
      return navigateToLocalWaypointAndLog(api, ship, waypoint);
    }
  }

  // If at a jump gate, go to a nearby system with unexplored waypoints or
  // missing market data.
  if (currentWaypoint.isJumpGate) {
    // We look for systems within the current jump gate's radius that have
    // unexplored waypoints or missing market data.
    // TODO(eseidel): Try removing this, it's redundant with the code below.
    final jumpGate = await getJumpGate(api, currentWaypoint);
    final sortedSystems = jumpGate.connectedSystems.toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    for (final connectedSystem in sortedSystems) {
      final systemWaypoints =
          await waypointCache.waypointsInSystem(connectedSystem.symbol);
      for (final waypoint in systemWaypoints) {
        if (_isMissingChartOrRecentMarketData(priceData, waypoint)) {
          shipInfo(
            ship,
            'Found unexplored system ${waypoint.symbol}, jumping.',
          );
          await undockIfNeeded(api, ship);
          await useJumpGateAndLog(api, ship, waypoint.systemSymbol);
          // Jumping is instant.
          return null;
        }
      }
    }
    const maxJumpDistance = 100;
    // If we get here, we've explored all systems connected to the jump gate.
    // Walk waypoints as far out as we can see until we find one missing
    // a chart or market data and route to there.
    await for (final destination in waypointsInJumpRadius(
      waypointCache: waypointCache,
      startSystem: currentWaypoint.systemSymbol,
      allowedJumps: maxJumpDistance,
    )) {
      if (_isMissingChartOrRecentMarketData(priceData, destination)) {
        shipInfo(
          ship,
          'Found unexplored system ${destination.symbol}, routing.',
        );
        return beingRouteAndLog(
          api,
          ship,
          waypointCache,
          behaviorManager,
          destination.symbol,
        );
      }
    }
    // If we get here, we've explored all systems within maxJumpDistance jumps
    // of this system.  We just log an error and sleep.
    shipErr(
      ship,
      'No unexplored systems within $maxJumpDistance jumps of '
      '${currentWaypoint.systemSymbol}, sleeping.',
    );
    await behaviorManager.disableBehavior(ship, Behavior.explorer);
    return null;
  }

  // Otherwise, go to a jump gate.
  final jumpGate =
      await waypointCache.jumpGateWaypointForSystem(ship.nav.systemSymbol);
  if (jumpGate == null) {
    throw UnimplementedError('No jump gates in ${ship.nav.waypointSymbol}');
  }
  return navigateToLocalWaypointAndLog(api, ship, jumpGate);
}
