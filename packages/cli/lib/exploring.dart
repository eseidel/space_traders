import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// Visits the local market if we're at a waypoint with a market.
/// Will return the market if we visited it, otherwise null.
/// Market data will be recorded if needed.
/// Market data only be refreshed if we haven't refreshed in 5 minutes.
Future<Market?> visitLocalMarket(
  Api api,
  Database db,
  Caches caches,
  Ship ship, {
  Duration maxAge = const Duration(minutes: 5),
  DateTime Function() getNow = defaultGetNow,
}) async {
  // If we're currently at a market, record the prices and refuel.
  // TODO(eseidel): Use a MarketListing lookup instead?
  final waypointSymbol = ship.waypointSymbol;
  final waypoint = await caches.waypoints.waypoint(waypointSymbol);
  if (!waypoint.hasMarketplace) {
    return null;
  }
  // This could avoid the dock and market lookup if the caller
  // doesn't need the Market value, we don't need fuel and we have
  // recent market data.
  await dockIfNeeded(api, caches.ships, ship);
  final market = await recordMarketDataIfNeededAndLog(
    caches.marketPrices,
    caches.markets,
    ship,
    waypointSymbol,
    maxAge: maxAge,
    getNow: getNow,
  );
  if (ship.usesFuel) {
    try {
      await refuelIfNeededAndLog(
        api,
        db,
        caches.marketPrices,
        caches.agent,
        caches.ships,
        market,
        ship,
      );
    } on ApiException catch (e) {
      shipErr(ship, 'Failed to refuel: $e');
    }
  }
  return market;
}

/// Visits the local shipyard if we're at a waypoint with a shipyard.
/// Records shipyard data if needed.
Future<void> visitLocalShipyard(
  Api api,
  Database db,
  WaypointCache waypoints,
  ShipyardPrices shipyardPrices,
  StaticCaches staticCaches,
  AgentCache agentCache,
  Ship ship,
) async {
  // TODO(eseidel): Use a ChartingCache lookup instead?
  final waypointSymbol = ship.waypointSymbol;
  final waypoint = await waypoints.waypoint(waypointSymbol);
  if (!waypoint.hasShipyard) {
    return;
  }
  final shipyard = await getShipyard(api, waypointSymbol);
  // TODO(eseidel): We should only visit the shipyard if we don't
  // have recent prices.
  recordShipyardDataAndLog(shipyardPrices, shipyard, ship);
  recordShipyardShips(staticCaches, shipyard.ships);
}
