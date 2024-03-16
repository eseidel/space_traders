import 'package:cli/caches.dart';
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
  final waypointSymbol = ship.waypointSymbol;
  final hasMarketplace = await caches.waypoints.hasMarketplace(waypointSymbol);
  if (!hasMarketplace) {
    return null;
  }
  // This could avoid the dock and market lookup if the caller
  // doesn't need the Market value, we don't need fuel and we have
  // recent market data.
  await dockIfNeeded(db, api, ship);
  final market = await recordMarketDataIfNeededAndLog(
    db,
    caches.markets,
    ship,
    waypointSymbol,
    maxAge: maxAge,
    getNow: getNow,
  );
  if (ship.usesFuel) {
    final medianFuelPurchasePrice =
        await db.medianMarketPurchasePrice(TradeSymbol.FUEL);
    try {
      await refuelIfNeededAndLog(
        api,
        db,
        caches.agent,
        market,
        ship,
        medianFuelPurchasePrice: medianFuelPurchasePrice,
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
  Database db,
  Api api,
  WaypointCache waypoints,
  StaticCaches staticCaches,
  AgentCache agentCache,
  Ship ship,
) async {
  final waypointSymbol = ship.waypointSymbol;
  final hasShipyard = await waypoints.hasShipyard(waypointSymbol);
  if (!hasShipyard) {
    return;
  }

  await recordShipyardDataIfNeededAndLog(
    db,
    api,
    staticCaches,
    ship,
    waypointSymbol,
  );
}

/// Record market data and log the result and returns the market.
/// This is the preferred way to get the local Market.
Future<Market> recordMarketDataIfNeededAndLog(
  Database db,
  MarketCache marketCache,
  Ship ship,
  WaypointSymbol marketSymbol, {
  Duration maxAge = const Duration(minutes: 5),
  DateTime Function() getNow = defaultGetNow,
}) async {
  if (ship.waypointSymbol != marketSymbol) {
    throw ArgumentError.value(
      marketSymbol,
      'marketSymbol',
      '${ship.symbol} is not at $marketSymbol, ${ship.waypointSymbol}.',
    );
  }
  // If we have market data more recent than maxAge, don't bother refreshing.
  // This prevents ships from constantly refreshing the same data.
  if (await db.hasRecentMarketPrices(marketSymbol, maxAge)) {
    var market = marketCache.fromCache(marketSymbol);
    if (market == null || market.tradeGoods.isEmpty) {
      market = await marketCache.refreshMarket(marketSymbol);
    }
    return market;
  }
  final market = await marketCache.refreshMarket(marketSymbol);
  await recordMarketData(db, market, getNow: getNow);
  // Powershell needs an extra space after the emoji.
  shipInfo(ship, '✍️  market data @ ${market.waypointSymbol.sectorLocalName}');
  return market;
}

/// Record shipyard data and log the result.
Future<void> recordShipyardDataIfNeededAndLog(
  Database db,
  Api api,
  StaticCaches staticCaches,
  Ship ship,
  WaypointSymbol shipyardSymbol, {
  Duration maxAge = const Duration(minutes: 5),
  DateTime Function() getNow = defaultGetNow,
}) async {
  if (ship.waypointSymbol != shipyardSymbol) {
    throw ArgumentError.value(
      shipyardSymbol,
      'shipyardSymbol',
      '${ship.symbol} is not at $shipyardSymbol, ${ship.waypointSymbol}.',
    );
  }
  // If we have shipyard data more recent than maxAge, don't bother refreshing.
  // This prevents ships from constantly refreshing the same data.
  if (await db.hasRecentShipyardPrices(shipyardSymbol, maxAge)) {
    return;
  }
  final shipyard = await getShipyard(api, shipyardSymbol);
  recordShipyardDataAndLog(db, staticCaches, shipyard, ship);
}
