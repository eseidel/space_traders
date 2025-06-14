import 'package:cli/api.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/compare.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:types/types.dart';

export 'package:cli/api.dart';
export 'package:cli/cache/behavior_snapshot.dart';
export 'package:cli/cache/market_cache.dart';
export 'package:cli/cache/ship_snapshot.dart';
export 'package:cli/cache/static_cache.dart';
export 'package:cli/cache/waypoint_cache.dart';
export 'package:cli/nav/jump_cache.dart';
export 'package:cli/nav/route.dart';
export 'package:cli/nav/system_connectivity.dart';

/// Container for all the caches.
class Caches {
  /// Creates a new cache.
  @visibleForTesting
  Caches({
    required this.marketPrices,
    required this.systems,
    required this.waypoints,
    required this.markets,
    required this.routePlanner,
    required this.factions,
    required this.systemConnectivity,
    required this.galaxy,
  });

  /// Stats about the galaxy.
  final GalaxyStats galaxy;

  /// The historical market price data.
  // TODO(eseidel): Remove this (need to fix trader.dart first).
  MarketPriceSnapshot marketPrices;

  /// The in memory cache of known systems.
  SystemsSnapshot systems;

  /// The cache of system connectivity.
  SystemConnectivity systemConnectivity;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of markets.
  final MarketCache markets;

  /// The route planner.
  RoutePlanner routePlanner;

  /// Factions cache.  Factions never change, so just holding them
  /// directly as a list.
  final List<Faction> factions;

  /// Load the cache from disk and network.
  static Future<Caches> loadOrFetch(
    Api api,
    Database db, {
    Future<http.Response> Function(Uri uri) httpGet = defaultHttpGet,
  }) async {
    // Force refresh ships and contracts in case we've been offline.
    await fetchShips(db, api);
    await fetchContracts(db, api);

    final marketPrices = await db.marketPrices.snapshotAll();

    // TODO(eseidel): This only needs to happen once per reset.
    await fetchExports(db, api.data);

    final systems = await db.systems.snapshotAllSystems();
    final waypoints = WaypointCache(api, db);
    final markets = MarketCache(db, api);
    final jumpGates = await db.jumpGates.snapshotAll();
    final constructionSnapshot = await db.construction.snapshotAll();
    final systemConnectivity = SystemConnectivity.fromJumpGates(
      jumpGates,
      constructionSnapshot,
    );
    final routePlanner = RoutePlanner.fromSystemsSnapshot(
      systems,
      systemConnectivity,
      sellsFuel: await defaultSellsFuel(db),
    );

    // TODO(eseidel): This only needs to happen once per reset.
    final factions = await fetchFactions(db, api.factions);

    final galaxy = await getGalaxyStats(api);
    return Caches(
      marketPrices: marketPrices,
      systems: systems,
      waypoints: waypoints,
      markets: markets,
      routePlanner: routePlanner,
      factions: factions,
      systemConnectivity: systemConnectivity,
      galaxy: galaxy,
    );
  }

  /// Called when routing information changes (e.g. when we complete
  /// a jump gate, find a new jump gate, or a jump gate breaks).
  Future<void> updateRoutingCaches(Database db) async {
    if (systems.systemsCount < galaxy.systemCount ||
        systems.waypointsCount < galaxy.waypointCount) {
      logger.info('Systems Snapshot is incomplete, reloading.');
      systems = await db.systems.snapshotAllSystems();
    }

    final jumpGateSnapshot = await db.jumpGates.snapshotAll();
    final constructionSnapshot = await db.construction.snapshotAll();
    final systemConnectivity = SystemConnectivity.fromJumpGates(
      jumpGateSnapshot,
      constructionSnapshot,
    );
    routePlanner = RoutePlanner.fromSystemsSnapshot(
      systems,
      systemConnectivity,
      sellsFuel: await defaultSellsFuel(db),
    );
  }
}

T _checkForChanges<T>({
  required T current,
  required T server,
  required List<Map<String, dynamic>> Function(T) toJsonList,
}) {
  final currentJson = toJsonList(current);
  final serverJson = toJsonList(server);
  if (!jsonMatches(currentJson, serverJson)) {
    logger.warn('$T changed, updating cache.');
    return server;
  }
  return current;
}

/// Class to hold state for updating caches at the top of the loop.
class TopOfLoopUpdater {
  /// Number of requests between checks to ensure ships are up to date.
  final int requestsBetweenChecks = 100;

  int _requestsSinceLastCheck = 0;

  /// Update the caches at the top of the loop.
  Future<void> updateAtTopOfLoop(Caches caches, Database db, Api api) async {
    // MarketCache only live for one loop over the ships.
    caches.markets.resetForLoop();

    // The ships check races with the code in continueNavigationIfNeeded which
    // knows how to update the ShipNavStatus from IN_TRANSIT to IN_ORBIT when
    // a ship has arrived.  We could add some special logic here to ignore
    // that false positive.  This check is called at the top of every loop
    // and might notice that a ship has arrived before the ship logic gets
    // to run and update the status.
    _requestsSinceLastCheck++;
    if (_requestsSinceLastCheck >= requestsBetweenChecks) {
      _requestsSinceLastCheck = 0;
      // This does not need to assign to anything, fetchContracts updates
      // the db already.
      _checkForChanges(
        current: await db.contracts.snapshotAll(),
        server: await fetchContracts(db, api),
        // Use OpenAPI's toJson to restrict to only the fields the server sends.
        toJsonList: (e) =>
            e.contracts.map((e) => e.toOpenApi().toJson()).toList(),
      );
      _checkForChanges(
        current: await ShipSnapshot.load(db)
          ..updateForServerTime(DateTime.timestamp()),
        server: await fetchShips(db, api),
        // Ignore the cooldown field, since even with updateForServerTime, it's
        // hard to exactly match the server.
        toJsonList: (e) =>
            e.ships.map((e) => e.toJson()..['cooldown'] = null).toList(),
      );
      // We could just upsert instead?
      await db.upsertAgent(
        _checkForChanges(
          current: (await db.getMyAgent())!,
          server: await getMyAgent(api),
          toJsonList: (e) => [e.toOpenApi().toJson()],
        ),
      );
    }

    // Should all be deleted from Caches.
    caches.marketPrices = await db.marketPrices.snapshotAll();
  }
}

/// Load all factions from the API.
// With our out-of-process rate limiting, this won't matter that it uses
// a separate API client.
Future<List<Faction>> allFactions(FactionsApi factionsApi) async {
  return fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response.data, response.meta);
  }).toList();
}

/// Loads the factions from the database, or fetches them from the API if
/// they're not cached.
Future<List<Faction>> fetchFactions(
  Database db,
  FactionsApi factionsApi,
) async {
  final cachedFactions = await db.allFactions();
  if (cachedFactions.length >= FactionSymbol.values.length) {
    return Future.value(cachedFactions.toList());
  }
  final factions = await allFactions(factionsApi);
  for (final faction in factions) {
    await db.upsertFaction(faction);
  }
  return factions;
}

/// Loads exports from the api and converts them to the old-style
/// TradeExport list.
Future<TradeExportSnapshot> fetchExports(Database db, DataApi dataApi) async {
  final cachedExportsJson = await db.getAllFromStaticCache(type: TradeExport);
  if (cachedExportsJson.isNotEmpty) {
    final exports = cachedExportsJson.map(TradeExport.fromJson).toList();
    return TradeExportSnapshot(exports);
  }

  final response = await dataApi.getSupplyChain();
  // Build the old-style TradeExport list from the response.
  // The server's new API covers things other than TradeSymbols.
  final exports = <TradeExport>[];
  for (final entry in response.data.exportToImportMap.entries.entries) {
    final export = TradeSymbol.fromJson(entry.key);
    final imports = entry.value.map(TradeSymbol.fromJson);
    exports.add(TradeExport(export: export, imports: imports.toList()));
  }
  for (final export in exports) {
    await db.upsertInStaticCache(
      type: TradeExport,
      key: export.export.toJson(),
      json: export.toJson(),
    );
  }
  return TradeExportSnapshot(exports);
}

/// Creates a new AgentCache from the API.
Future<Agent> fetchAndCacheMyAgent(Database db, Api api) async {
  final agent = await getMyAgent(api);
  // Just in case agent symbol is stale.
  await db.config.setAgentSymbol(agent.symbol);
  await db.upsertAgent(agent);
  return agent;
}

/// Creates a new JumpGateCache from the API.
Future<JumpGate> fetchAndCacheJumpGate(
  Database db,
  Api api,
  WaypointSymbol waypointSymbol,
) async {
  final jumpGate = await getJumpGate(api, waypointSymbol);
  await db.jumpGates.upsert(jumpGate);
  return jumpGate;
}

/// Gets the JumpGate for the given waypoint symbol from the database, or
/// fetches it from the API and caches it.
Future<JumpGate> getOrFetchJumpGate(
  Database db,
  Api api,
  WaypointSymbol waypointSymbol,
) async {
  return (await db.jumpGates.get(waypointSymbol)) ??
      await fetchAndCacheJumpGate(db, api, waypointSymbol);
}

/// Fetches all of the user's contracts.
Future<ContractSnapshot> fetchContracts(Database db, Api api) async {
  final contracts = await allMyContracts(api).toList();
  for (final contract in contracts) {
    await db.contracts.upsert(contract);
  }
  return ContractSnapshot(contracts);
}
