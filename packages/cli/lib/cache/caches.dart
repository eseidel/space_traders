import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/jump_gate_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/shipyard_listing_cache.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
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
export 'package:cli/cache/behavior_cache.dart';
export 'package:cli/cache/charting_cache.dart';
export 'package:cli/cache/construction_cache.dart';
export 'package:cli/cache/contract_cache.dart';
export 'package:cli/cache/jump_gate_cache.dart';
export 'package:cli/cache/market_cache.dart';
export 'package:cli/cache/market_prices.dart';
export 'package:cli/cache/ship_cache.dart';
export 'package:cli/cache/shipyard_listing_cache.dart';
export 'package:cli/cache/shipyard_prices.dart';
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
    required this.ships,
    required this.shipyardPrices,
    required this.systems,
    required this.waypoints,
    required this.markets,
    required this.contracts,
    required this.behaviors,
    required this.charting,
    required this.routePlanner,
    required this.factions,
    required this.static,
    required this.marketListings,
    required this.construction,
    required this.systemConnectivity,
    required this.jumpGates,
    required this.shipyardListings,
  });

  /// The agent cache.
  final AgentCache agent;

  /// The historical market price data.
  final MarketPrices marketPrices;

  /// The ship cache.
  final ShipCache ships;

  /// The contract cache.
  ContractSnapshot contracts;

  /// Known shipyard listings.
  final ShipyardListingCache shipyardListings;

  /// The historical shipyard prices.
  final ShipyardPrices shipyardPrices;

  /// The cache of systems.
  final SystemsCache systems;

  /// The cache of system connectivity.
  final SystemConnectivity systemConnectivity;

  /// The cache of construction data.
  final ConstructionCache construction;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of jump gates.
  final JumpGateSnapshot jumpGates;

  /// The cache of markets descriptions.
  /// This is currently updated at the top of every loop.
  MarketListingSnapshot marketListings;

  /// The cache of markets.
  final MarketCache markets;

  /// The cache of behaviors.
  final BehaviorCache behaviors;

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
    final agent = await AgentCache.loadOrFetch(db, api);
    // Intentionally do not load ships from disk (they change too often).
    final ships = await ShipCache.loadOrFetch(api, fs: fs, forceRefresh: true);
    final marketPrices = await MarketPrices.load(db);
    final shipyardPrices = await ShipyardPrices.load(db);
    final shipyardListings = ShipyardListingCache.load(fs);
    final systems = await SystemsCache.loadOrFetch(fs, httpGet: httpGet);
    final static = StaticCaches.load(fs);
    final charting = ChartingCache(db);
    final construction = ConstructionCache(db);
    final marketListings = await MarketListingSnapshot.load(db);
    final waypoints = WaypointCache(
      api,
      systems,
      charting,
      construction,
      static.waypointTraits,
    );
    final markets = MarketCache(db, api, static.tradeGoods);
    // Intentionally force refresh contracts in case we've been offline.
    final contracts = await fetchContracts(db, api);
    final behaviors = BehaviorCache.load(fs);

    final jumpGates = await JumpGateSnapshot.load(db);
    final constructionSnapshot = await ConstructionSnapshot.load(db);
    final systemConnectivity =
        SystemConnectivity.fromJumpGates(jumpGates, constructionSnapshot);
    final routePlanner = RoutePlanner.fromSystemsCache(
      systems,
      systemConnectivity,
      sellsFuel: defaultSellsFuel(marketListings),
    );

    // Make sure factions are loaded.
    final factions = await loadFactions(db, api.factions);

    return Caches(
      agent: agent,
      ships: ships,
      marketPrices: marketPrices,
      shipyardPrices: shipyardPrices,
      systems: systems,
      waypoints: waypoints,
      markets: markets,
      contracts: contracts,
      behaviors: behaviors,
      charting: charting,
      static: static,
      routePlanner: routePlanner,
      factions: factions,
      marketListings: marketListings,
      construction: construction,
      systemConnectivity: systemConnectivity,
      jumpGates: jumpGates,
      shipyardListings: shipyardListings,
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

  /// Update the caches at the top of the loop.
  Future<void> updateAtTopOfLoop(Database db, Api api) async {
    // MarketCache only live for one loop over the ships.
    markets.resetForLoop();

    // This check races with the code in continueNavigationIfNeeded which
    // knows how to update the ShipNavStatus from IN_TRANSIT to IN_ORBIT when
    // a ship has arrived.  We could add some special logic here to ignore
    // that false positive.  This check is called at the top of every loop
    // and might notice that a ship has arrived before the ship logic gets
    // to run and update the status.
    await ships.ensureUpToDate(api);
    await agent.ensureAgentUpToDate(api);
    contracts = await contracts.ensureUpToDate(db, api);

    marketListings = await MarketListingSnapshot.load(db);
  }
}

/// Load all factions from the API.
// With our out-of-process rate limiting, this won't matter that it uses
// a separate API client.
Future<List<Faction>> allFactions(FactionsApi factionsApi) async {
  final factions = await fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response!.data, response.meta);
  }).toList();
  return factions;
}

/// Loads the factions from the database, or fetches them from the API if
/// they're not cached.
Future<List<Faction>> loadFactions(Database db, FactionsApi factionsApi) async {
  final cachedFactions = await db.allFactions();
  if (cachedFactions.isNotEmpty) {
    return Future.value(cachedFactions.toList());
  }
  final factions = await allFactions(factionsApi);
  await db.cacheFactions(factions);
  return factions;
}
