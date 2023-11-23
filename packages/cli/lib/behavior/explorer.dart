import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/exploring.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

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

/// Returns the symbol of a waypoint in the system missing a chart.
@visibleForTesting
Future<WaypointSymbol?> waypointSymbolNeedingExploration(
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship,
  System system, {
  required Duration maxAge,
  required bool Function(WaypointSymbol waypointSymbol)? filter,
  required WaypointCache waypointCache,
}) async {
  final WaypointSymbol? start;
  if (ship.systemSymbol == system.systemSymbol) {
    start = ship.waypointSymbol;
  } else {
    start = system.jumpGateWaypoint?.waypointSymbol;
  }
  final systemWaypoints = system.waypoints.toList(); // Copy so we can sort.
  if (start != null) {
    final startWaypoint = systemsCache.waypointFromSymbol(start);
    systemWaypoints.sort(
      (a, b) =>
          a.distanceTo(startWaypoint).compareTo(b.distanceTo(startWaypoint)),
    );
  }

  for (final systemWaypoint in systemWaypoints) {
    final waypointSymbol = systemWaypoint.waypointSymbol;
    if (filter != null && !filter(waypointSymbol)) {
      continue;
    }
    // Try and fetch the waypoint from the server or our cache.
    final waypoint = await waypointCache.waypoint(waypointSymbol);
    // We know we've updated the waypoint at this point, so if it's not
    // stored in our charting cache, we know it has no chart.
    final values = chartingCache[waypointSymbol];
    if (values == null) {
      shipInfo(ship, '$waypointSymbol is missing chart, routing.');
      return waypointSymbol;
    }
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
  // SystemConnectivity systemConnectivity,
  ChartingCache chartingCache,
  MarketPrices marketPrices,
  ShipyardPrices shipyardPrices,
  Ship ship, {
  required SystemSymbol startSystemSymbol,
  required WaypointCache waypointCache,
  bool Function(WaypointSymbol waypointSymbol)? filter,
  Duration maxAge = defaultMaxAge,
}) async {
  // Find all systems in the jumpgate network.
  final startSystem = systemsCache[startSystemSymbol];
  // final clusterId = systemConnectivity.clusterIdForSystem(startSystemSymbol);
  // final reachableSystemSymbols =
  //     systemConnectivity.systemSymbolsByClusterId(clusterId);
  // // Sort them by distance from where we are.
  // final reachableSystems =
  //     reachableSystemSymbols.map(systemsCache.systemBySymbol).toList();

  // final sortedSystems = reachableSystems
  //     .sortedBy<num>((system) => system.distanceTo(startSystem))
  //     .toList();
  final sortedSystems = [startSystem];
  // Walk through the list finding one missing either a chart or market data.
  for (final system in sortedSystems) {
    final symbol = await waypointSymbolNeedingExploration(
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

/// Find the nearest headquarters to the ship's current location.
WaypointSymbol nearestHeadquarters(
  // SystemConnectivity systemConnectivity,
  SystemsCache systemsCache,
  List<Faction> factions,
  SystemSymbol startSystemSymbol,
) {
  final factionHqs = factions.map((e) => e.headquartersSymbol).toList();
  final startSystem = systemsCache[startSystemSymbol];
  final reachableHqs =
      factionHqs.where((hq) => hq.systemSymbol == startSystemSymbol).toList();
  // .where(
  //   (hq) => systemConnectivity.canJumpBetweenSystemSymbols(
  //     startSystemSymbol,
  //     hq.systemSymbol,
  //   ),
  // )
  // .toList();
  final sortedHqs = reachableHqs
      .sortedBy<num>(
        (hq) => systemsCache[hq.systemSymbol].distanceTo(startSystem),
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
  BehaviorState state,
) async {
  if (ship.fuelPercentage > 0.3) {
    return null;
  }
  shipWarn(ship, 'Fuel critically low, routing to market.');
  var marketSymbol = nearbyMarketWhichTrades(
    caches.systems,
    caches.marketListings,
    waypoint.waypointSymbol,
    TradeSymbol.FUEL,
  );
  if (marketSymbol == null) {
    shipErr(ship, 'No nearby market trades fuel, routing to nearest hq.');
    marketSymbol = nearestHeadquarters(
      // caches.systemConnectivity,
      caches.systems,
      caches.factions,
      ship.systemSymbol,
    );
  }
  final waitUntil = await beingNewRouteAndLog(
    api,
    db,
    centralCommand,
    caches,
    ship,
    state,
    marketSymbol,
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
  await visitLocalMarket(api, db, caches, waypoint, ship, getNow: getNow);
  // We might buy a ship if we're at a ship yard.
  await visitLocalShipyard(
    api,
    db,
    caches.shipyardPrices,
    caches.static,
    caches.agent,
    waypoint,
    ship,
  );

  if (willCompleteBehavior) {
    // Explore behavior never changes, but it's still the correct thing to
    // reset our state after completing on loop of "explore".
    state.isComplete = true;
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
    state,
  );
  if (refuelWaitTime != null) {
    return refuelWaitTime;
  }

  final explorerWaypoints = centralCommand
      .otherExplorerWaypoints(ship.shipSymbol)
      .toSet()
      // It's OK for multiple explorers to use the same jumpgate.
      .where(caches.systems.isJumpGate)
      .toSet();

  // Walk waypoints as far out as we can see until we find one missing
  // a chart or market data and route to there.
  final startTime = getNow();
  final destinationSymbol = await findNewWaypointSymbolToExplore(
    caches.systems,
    // caches.systemConnectivity,
    caches.charting,
    caches.marketPrices,
    caches.shipyardPrices,
    ship,
    startSystemSymbol: ship.systemSymbol,
    // TODO(eseidel): Once we leave the initial system, explorers should stay
    // at least a system apart.
    filter: (waypointSymbol) => !explorerWaypoints.contains(waypointSymbol),
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
      db,
      centralCommand,
      caches,
      ship,
      state,
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
