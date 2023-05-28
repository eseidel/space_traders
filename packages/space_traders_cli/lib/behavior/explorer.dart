import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

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
) async {
  if (ship.isInTransit) {
    // Go back to sleep until we arrive.
    return logRemainingTransitTime(ship);
  }
  // Check our current waypoint.  If it's not charted or doesn't have current
  // market data, chart it and/or record market data.
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
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
  // Check the current system waypoints.
  // If any are not explored, or have a market but don't have recent market
  // data, got there.
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
    // Should look at systems connected to hq and go to the one closest to
    // hq with unexplored waypoints or missing market data.
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
    // If we get here, we've explored all systems connected to the jump gate.
    // So jump to the furthest and try again.
    final furthestSystem = sortedSystems.last;
    shipWarn(
      ship,
      'All systems connected to ${currentWaypoint.symbol} explored, '
      'jumping to furthest system, ${furthestSystem.symbol}.',
    );
    await undockIfNeeded(api, ship);
    await useJumpGateAndLog(api, ship, furthestSystem.symbol);
    // Jumping is instant.
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
