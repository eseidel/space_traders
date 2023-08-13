import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';

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
      !marketPrices.hasRecentMarketData(
        waypoint.waypointSymbol,
        maxAge: maxAge,
      );
}

bool _isMissingRecentShipyardData(
  ShipyardPrices shipyardPrices,
  Waypoint waypoint, {
  required Duration maxAge,
}) {
  return waypoint.hasShipyard &&
      !shipyardPrices.hasRecentShipyardData(
        waypoint.waypointSymbol,
        maxAge: maxAge,
      );
}

/// Visits the local market if we're at a waypoint with a market.
/// Will return the market if we visited it, otherwise null.
/// Market data will be recorded if needed.
/// Market data only be refreshed if we haven't refreshed in 5 minutes.
Future<Market?> visitLocalMarket(
  Api api,
  Database db,
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
  await dockIfNeeded(api, caches.ships, ship);
  final market = await recordMarketDataIfNeededAndLog(
    caches.marketPrices,
    caches.markets,
    ship,
    waypoint.waypointSymbol,
    maxAge: maxAge,
  );
  if (ship.usesFuel) {
    await refuelIfNeededAndLog(
      api,
      db,
      caches.marketPrices,
      caches.agent,
      caches.ships,
      market,
      ship,
    );
  }
  return market;
}

/// Returns the symbol of a waypoint in the system missing a chart.
Future<WaypointSymbol?> _waypointSymbolNeedingExploration(
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship,
  System system, {
  required Duration maxAge,
  required bool Function(SystemSymbol systemSymbol)? filter,
  required WaypointCache? waypointCache,
}) async {
  for (final systemWaypoint in system.waypoints) {
    final waypointSymbol = systemWaypoint.waypointSymbol;
    if (filter != null && !filter(systemWaypoint.systemSymbol)) {
      continue;
    }
    var values = chartingCache.valuesForSymbol(waypointSymbol);
    // Maybe the system is already charted and our cache is out of date?
    if (values == null && waypointCache != null) {
      await waypointCache.waypoint(waypointSymbol);
      values = chartingCache.valuesForSymbol(waypointSymbol);
    }
    if (values == null) {
      shipInfo(ship, '$waypointSymbol is missing chart, routing.');
      return waypointSymbol;
    }
    final waypoint =
        chartingCache.waypointFromSymbol(systemsCache, waypointSymbol)!;
    if (waypoint.hasMarketplace &&
        !marketPrices.hasRecentMarketData(waypointSymbol, maxAge: maxAge)) {
      shipInfo(
        ship,
        '$waypointSymbol is missing recent '
        '(${approximateDuration(maxAge)}) market data, '
        'routing.',
      );
      return waypointSymbol;
    }
    if (waypoint.hasShipyard &&
        !shipyardPrices.hasRecentShipyardData(waypointSymbol, maxAge: maxAge)) {
      shipInfo(
        ship,
        '$waypointSymbol is missing recent '
        '(${approximateDuration(maxAge)}) shipyard data, '
        'routing.',
      );
      return waypointSymbol;
    }
  }
  return null;
}

/// Returns the closet waypoint worth exploring.
Future<WaypointSymbol?> findNewWaypointSymbolToExplore(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  ChartingCache chartingCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship, {
  required SystemSymbol startSystemSymbol,
  WaypointCache? waypointCache,
  bool Function(SystemSymbol systemSymbol)? filter,
  Duration maxAge = defaultMaxAge,
}) async {
  // Find all systems in the jumpgate network.
  final startSystem = systemsCache.systemBySymbol(startSystemSymbol);
  final clusterId = systemConnectivity.clusterIdForSystem(startSystemSymbol);
  final reachableSystemSymbols =
      systemConnectivity.systemSymbolsByClusterId(clusterId);
  // Sort them by distance from where we are.
  final reachableSystems =
      reachableSystemSymbols.map(systemsCache.systemBySymbol).toList();

  final sortedSystems = reachableSystems
      .sortedBy<num>((system) => system.distanceTo(startSystem))
      .toList();
  // Walk through the list finding one missing either a chart or market data.
  for (final system in sortedSystems) {
    // final distance = system.distanceTo(startSystem);
    // logger.info('Checking ${system.symbol} (distance $distance).');
    final symbol = await _waypointSymbolNeedingExploration(
      systemsCache,
      chartingCache,
      marketPrices,
      shipyardPrices,
      ship,
      system,
      waypointCache: waypointCache,
      maxAge: maxAge,
      filter: filter,
    );
    if (symbol != null) {
      return symbol;
    }
  }
  return null;
}

Future<WaypointSymbol> _nearestHeadquarters(
  Database db,
  SystemConnectivity systemConnectivity,
  SystemsCache systemsCache,
  AgentCache agentCache,
  Ship ship,
) async {
  final factionHqs =
      (await loadFactions(db)).map((e) => e.headquartersSymbol).toList();
  final startSystem = systemsCache.systemBySymbol(ship.systemSymbol);
  final reachableHqs = factionHqs
      .where(
        (hq) => systemConnectivity.canJumpBetweenSystemSymbols(
          ship.systemSymbol,
          hq.systemSymbol,
        ),
      )
      .toList();
  final sortedHqs = reachableHqs
      .sortedBy<num>(
        (hq) => systemsCache
            .systemBySymbol(hq.systemSymbol)
            .distanceTo(startSystem),
      )
      .toList();
  // There is always a reacahble HQ since we don't warp yet.
  return sortedHqs.first;
}

/// If we're low on fuel, route to the nearest market which trades fuel.
Future<DateTime?> routeForEmergencyFuelingIfNeeded(
  Api api,
  Database db,
  Caches caches,
  CentralCommand centralCommand,
  Waypoint waypoint,
  Ship ship,
) async {
  if (ship.fuelPercentage > 0.4) {
    return null;
  }
  shipWarn(ship, 'Fuel critically low, routing to market.');
  var destination = (await nearbyMarketWhichTrades(
    caches.systems,
    caches.waypoints,
    caches.markets,
    waypoint.waypointSymbol,
    TradeSymbol.FUEL,
    maxJumps: 5,
  ))
      ?.waypointSymbol;
  if (destination == null) {
    shipErr(ship, 'No nearby market trades fuel, routing to nearest hq.');
    destination = await _nearestHeadquarters(
      db,
      caches.systemConnectivity,
      caches.systems,
      caches.agent,
      ship,
    );
  }
  final waitUntil = await beingNewRouteAndLog(
    api,
    ship,
    caches.ships,
    caches.systems,
    caches.routePlanner,
    centralCommand,
    destination,
  );
  return waitUntil;
}

/// One loop of the exploring logic.
Future<DateTime?> advanceExplorer(
  Api api,
  Database db,
  CentralCommand centralCommand,
  Caches caches,
  BehaviorState state,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final maxAge = centralCommand.maxAgeForExplorerData;
  final waypoint = await caches.waypoints.waypoint(ship.waypointSymbol);
  // advanceExplorer is only ever called when we're idle at a location, so
  // either it's the first time and we need to set a destination, or we've just
  // completed a loop.  This _isMissingChartOrRecentPriceData is really our
  // check for "did we just do a loop"?  If so, we complete the behavior.
  final willCompleteBehavior = _isMissingChartOrRecentPriceData(
    caches.marketPrices,
    caches.shipyardPrices,
    waypoint,
    maxAge: maxAge,
  );
  // We still do our charting and market visits even if this isn't going to
  // cause us to complete the behavior (e.g. we're refueling).
  if (waypoint.chart == null) {
    await chartWaypointAndLog(api, caches.charting, ship);
  }
  // If we don't visit the market, we won't refuel (even when low).
  await visitLocalMarket(api, db, caches, waypoint, ship);
  // We might buy a ship if we're at a ship yard.
  await centralCommand.visitLocalShipyard(
    api,
    db,
    caches.shipyardPrices,
    caches.agent,
    waypoint,
    ship,
  );

  if (willCompleteBehavior) {
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    centralCommand.completeBehavior(ship.shipSymbol);
    return null;
  }

  // So far this is only needed for Explorers since they go to waypoints
  // which do not have markets.  Other behaviors always stick to markets.
  final refuelWaitTime = await routeForEmergencyFuelingIfNeeded(
    api,
    db,
    caches,
    centralCommand,
    waypoint,
    ship,
  );
  if (refuelWaitTime != null) {
    return refuelWaitTime;
  }

  final probeSystems =
      centralCommand.otherExplorerSystems(ship.shipSymbol).toSet();
  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  final startTime = getNow();
  // TODO(eseidel): Early on it might be useful to prefer systems with a greater
  // chance of selling ship parts (e.g. orbital stations?)
  final destinationSymbol = await findNewWaypointSymbolToExplore(
    caches.systems,
    caches.systemConnectivity,
    caches.charting,
    caches.marketPrices,
    caches.shipyardPrices,
    ship,
    startSystemSymbol: ship.systemSymbol,
    filter: (SystemSymbol systemSymbol) => !probeSystems.contains(systemSymbol),
    maxAge: maxAge,
    waypointCache: caches.waypoints,
  );
  final endTime = getNow();
  final elapsed = endTime.difference(startTime);
  if (elapsed > const Duration(seconds: 5)) {
    shipErr(
      ship,
      'Took ${approximateDuration(elapsed)} to find next system to explore.',
    );
  }
  if (destinationSymbol != null) {
    return beingNewRouteAndLog(
      api,
      ship,
      caches.ships,
      caches.systems,
      caches.routePlanner,
      centralCommand,
      destinationSymbol,
    );
  }
  // If we get here, we've explored all systems within maxJumpDistance jumps
  // of this system.
  shipWarn(ship, 'No unexplored systems near ${waypoint.systemSymbol}.');
  final newMaxAge = centralCommand.shortenMaxAgeForExplorerData();
  shipWarn(
    ship,
    'Shortened maxAge to ${approximateDuration(newMaxAge)} and resuming.',
  );
  return null;
}
