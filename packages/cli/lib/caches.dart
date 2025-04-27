import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/contract_snapshot.dart';
import 'package:cli/cache/jump_gate_snapshot.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_listing_snapshot.dart';
import 'package:cli/cache/market_price_snapshot.dart';
import 'package:cli/cache/ship_snapshot.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/compare.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:types/types.dart';

export 'package:cli/api.dart';
export 'package:cli/cache/agent_cache.dart';
export 'package:cli/cache/behavior_snapshot.dart';
export 'package:cli/cache/charting_cache.dart';
export 'package:cli/cache/construction_cache.dart';
export 'package:cli/cache/contract_snapshot.dart';
export 'package:cli/cache/jump_gate_snapshot.dart';
export 'package:cli/cache/market_cache.dart';
export 'package:cli/cache/market_listing_snapshot.dart';
export 'package:cli/cache/market_price_snapshot.dart';
export 'package:cli/cache/ship_snapshot.dart';
export 'package:cli/cache/shipyard_listing_snapshot.dart';
export 'package:cli/cache/shipyard_price_snapshot.dart';
export 'package:cli/cache/static_cache.dart';
export 'package:cli/cache/systems_cache.dart';
export 'package:cli/cache/waypoint_cache.dart';
export 'package:cli/nav/jump_cache.dart';
export 'package:cli/nav/route.dart';
export 'package:cli/nav/system_connectivity.dart';
export 'package:file/file.dart';

/// Container for all the caches.
class Caches {
  /// Creates a new cache.
  @visibleForTesting
  Caches({
    required this.agent,
    required this.marketPrices,
    required this.systems,
    required this.waypoints,
    required this.markets,
    required this.charting,
    required this.routePlanner,
    required this.factions,
    required this.static,
    required this.construction,
    required this.systemConnectivity,
    required this.jumpGates,
  });

  /// The agent cache.
  final AgentCache agent;

  /// The historical market price data.
  // TODO(eseidel): Remove this (need to fix trader.dart first).
  MarketPriceSnapshot marketPrices;

  /// The cache of systems.
  final SystemsCache systems;

  /// The cache of system connectivity.
  final SystemConnectivity systemConnectivity;

  /// The cache of construction data.
  final ConstructionCache construction;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of jump gates.
  // TODO(eseidel): This needs to update when changes!
  final JumpGateSnapshot jumpGates;

  /// The cache of markets.
  final MarketCache markets;

  /// The cache of charting data.
  final ChartingCache charting;

  /// The route planner.
  final RoutePlanner routePlanner;

  /// Cache of static data from the server.
  final StaticCaches static;

  /// Factions cache.  Factions never change, so just holding them
  /// directly as a list.
  final List<Faction> factions;

  /// Load the cache from disk and network.
  static Future<Caches> loadOrFetch(
    FileSystem fs,
    Api api,
    Database db, {
    Future<http.Response> Function(Uri uri) httpGet = defaultHttpGet,
  }) async {
    // Force refresh ships and contracts in case we've been offline.
    await fetchShips(db, api);
    await fetchContracts(db, api);

    final agent = await AgentCache.loadOrFetch(db, api);
    final marketPrices = await MarketPriceSnapshot.loadAll(db);
    final systems = await SystemsCache.loadOrFetch(fs, httpGet: httpGet);
    // Load exports before we load static caches.  We ignore the response
    // but then static.exports will be up to date.
    await loadExports(db, api.data);

    final static = StaticCaches(db);
    final charting = ChartingCache(db);
    final construction = ConstructionCache(db);
    final waypoints = WaypointCache(
      api,
      db,
      systems,
      charting,
      construction,
      static.waypointTraits,
    );
    final markets = MarketCache(db, api, static.tradeGoods);
    final jumpGates = await JumpGateSnapshot.load(db);
    final constructionSnapshot = await ConstructionSnapshot.load(db);
    final systemConnectivity = SystemConnectivity.fromJumpGates(
      jumpGates,
      constructionSnapshot,
    );
    // TODO(eseidel): Find a way to avoid fetching market listings here?
    final marketListings = await MarketListingSnapshot.load(db);
    final routePlanner = RoutePlanner.fromSystemsCache(
      systems,
      systemConnectivity,
      sellsFuel: defaultSellsFuel(marketListings),
    );

    // Make sure factions are loaded.
    final factions = await loadFactions(db, api.factions);

    return Caches(
      agent: agent,
      marketPrices: marketPrices,
      systems: systems,
      waypoints: waypoints,
      markets: markets,
      charting: charting,
      static: static,
      routePlanner: routePlanner,
      factions: factions,
      construction: construction,
      systemConnectivity: systemConnectivity,
      jumpGates: jumpGates,
    );
  }

  /// Called when routing information changes (e.g. when we complete
  /// a jump gate, find a new jump gate, or a jump gate breaks).
  Future<void> updateRoutingCaches() async {
    systemConnectivity.updateFromJumpGates(
      jumpGates,
      await construction.snapshot(),
    );
    routePlanner.clearRoutingCaches();
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
        current: await ContractSnapshot.load(db),
        server: await fetchContracts(db, api),
        // Use OpenAPI's toJson to restrict to only the fields the server sends.
        toJsonList:
            (e) => e.contracts.map((e) => e.toOpenApi().toJson()).toList(),
      );
      _checkForChanges(
        current: await ShipSnapshot.load(db)
          ..updateForServerTime(DateTime.timestamp()),
        server: await fetchShips(db, api),
        // Ignore the cooldown field, since even with updateForServerTime, it's
        // hard to exactly match the server.
        toJsonList:
            (e) => e.ships.map((e) => e.toJson()..['cooldown'] = null).toList(),
      );
      // caches.agent should be deleted.
      await caches.agent.updateAgent(
        _checkForChanges(
          current: caches.agent.agent,
          server: await getMyAgent(api),
          toJsonList: (e) => [e.toOpenApi().toJson()],
        ),
      );
    }

    // Should all be deleted from Caches.
    caches.marketPrices = await MarketPriceSnapshot.loadAll(db);
  }
}

/// Load all factions from the API.
// With our out-of-process rate limiting, this won't matter that it uses
// a separate API client.
Future<List<Faction>> allFactions(FactionsApi factionsApi) async {
  return fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response!.data, response.meta);
  }).toList();
}

/// Loads the factions from the database, or fetches them from the API if
/// they're not cached.
Future<List<Faction>> loadFactions(Database db, FactionsApi factionsApi) async {
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
Future<TradeExportSnapshot> loadExports(Database db, DataApi dataApi) async {
  final cachedExportsJson = await db.getAllFromStaticCache(type: TradeExport);
  if (cachedExportsJson.isNotEmpty) {
    final exports = cachedExportsJson.map(TradeExport.fromJson).toList();
    return TradeExportSnapshot(exports);
  }

  final response = await dataApi.getSupplyChain();
  // Build the old-style TradeExport list from the response.
  // The server's new API covers things other than TradeSymbols.
  final exports = <TradeExport>[];
  for (final entry in response!.data.exportToImportMap.entries) {
    final export = TradeSymbol.fromJson(entry.key);
    if (export == null) {
      continue;
    }
    final imports = entry.value.map((i) => TradeSymbol.fromJson(i)!);
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
