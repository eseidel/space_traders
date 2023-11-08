import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

export 'package:cli/api.dart';
export 'package:cli/cache/agent_cache.dart';
export 'package:cli/cache/behavior_cache.dart';
export 'package:cli/cache/charting_cache.dart';
export 'package:cli/cache/construction_cache.dart';
export 'package:cli/cache/contract_cache.dart';
export 'package:cli/cache/market_cache.dart';
export 'package:cli/cache/market_prices.dart';
export 'package:cli/cache/ship_cache.dart';
export 'package:cli/cache/shipyard_prices.dart';
export 'package:cli/cache/static_cache.dart';
export 'package:cli/cache/systems_cache.dart';
export 'package:cli/cache/waypoint_cache.dart';
export 'package:cli/nav/jump_cache.dart';
export 'package:cli/nav/route.dart';
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
  });

  /// The agent cache.
  final AgentCache agent;

  /// The historical market price data.
  final MarketPrices marketPrices;

  /// The ship cache.
  final ShipCache ships;

  /// The contract cache.
  final ContractCache contracts;

  /// The historical shipyard prices.
  final ShipyardPrices shipyardPrices;

  /// The cache of systems.
  final SystemsCache systems;

  /// The cache of construction data.
  final ConstructionCache construction;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of markets descriptions.
  final MarketListingCache marketListings;

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
  static Future<Caches> load(
    FileSystem fs,
    Api api,
    Database db, {
    Future<http.Response> Function(Uri uri) httpGet = defaultHttpGet,
  }) async {
    final agent = await AgentCache.load(api, fs: fs);
    final prices = MarketPrices.load(fs);
    // Intentionally do not load ships from disk (they change too often).
    final ships = await ShipCache.load(api, fs: fs, forceRefresh: true);
    final shipyard = ShipyardPrices.load(fs);
    final systems = await SystemsCache.load(fs, httpGet: httpGet);
    final static = StaticCaches.load(fs);
    final charting = ChartingCache.load(fs, static.waypointTraits);
    final construction = ConstructionCache.load(fs);
    final marketListings = MarketListingCache.load(fs, static.tradeGoods);
    final waypoints = WaypointCache(api, systems, charting, construction);
    final markets = MarketCache(api, marketListings, waypoints);
    // Intentionally force refresh contracts in case we've been offline.
    final contracts = await ContractCache.load(api, fs: fs, forceRefresh: true);
    final behaviors = BehaviorCache.load(fs);

    // final systemConnectivity = SystemConnectivity.fromSystemsCache(systems);
    // final jumps = JumpCache();
    final routePlanner = RoutePlanner(
      // jumpCache: jumps,
      systemsCache: systems,
      // systemConnectivity: systemConnectivity,
      sellsFuel: defaultSellsFuel(marketListings),
    );

    // Make sure factions are loaded.
    final factions = await loadFactions(db, api.factions);

    // We rarely modify contracts, so save them out here too.
    contracts.save();

    return Caches(
      agent: agent,
      marketPrices: prices,
      ships: ships,
      shipyardPrices: shipyard,
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
    );
  }

  /// Update the caches at the top of the loop.
  Future<void> updateAtTopOfLoop(Api api) async {
    // WaypointCache and MarketCache only live for one loop over the ships.
    waypoints.resetForLoop();
    markets.resetForLoop();

    // This check races with the code in continueNavigationIfNeeded which
    // knows how to update the ShipNavStatus from IN_TRANSIT to IN_ORBIT when
    // a ship has arrived.  We could add some special logic here to ignore
    // that false positive.  This check is called at the top of every loop
    // and might notice that a ship has arrived before the ship logic gets
    // to run and update the status.
    await ships.ensureUpToDate(api);
    await contracts.ensureUpToDate(api);
    await agent.ensureAgentUpToDate(api);

    // TODO(eseidel): Ship objects get modifed directly and ShipCache isn't told
    // about those modifications, so save it out every loop.
    ships.save();
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
    return Future.value(cachedFactions);
  }
  final factions = await allFactions(factionsApi);
  await db.cacheFactions(factions);
  return factions;
}
