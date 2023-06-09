import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/jump_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/surveys.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;

export 'package:cli/api.dart';
export 'package:cli/cache/agent_cache.dart';
export 'package:cli/cache/behavior_cache.dart';
export 'package:cli/cache/charting_cache.dart';
export 'package:cli/cache/contract_cache.dart';
export 'package:cli/cache/faction_cache.dart';
export 'package:cli/cache/jump_cache.dart';
export 'package:cli/cache/market_prices.dart';
export 'package:cli/cache/ship_cache.dart';
export 'package:cli/cache/shipyard_prices.dart';
export 'package:cli/cache/surveys.dart';
export 'package:cli/cache/systems_cache.dart';
export 'package:cli/cache/transactions.dart';
export 'package:cli/cache/waypoint_cache.dart';
export 'package:cli/nav/system_connectivity.dart';
export 'package:file/file.dart';

/// Container for all the caches.
class Caches {
  Caches._({
    required this.agent,
    required this.marketPrices,
    required this.ships,
    required this.shipyardPrices,
    required this.surveys,
    required this.systems,
    required this.systemConnectivity,
    required this.transactions,
    required this.waypoints,
    required this.markets,
    required this.contracts,
    required this.behaviors,
    required this.factions,
    required this.charting,
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

  /// The survey data.
  final SurveyData surveys;

  /// The cache of systems.
  final SystemsCache systems;

  /// Cache of system reachability.
  final SystemConnectivity systemConnectivity;

  /// The transaction log.
  final TransactionLog transactions;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of markets.
  final MarketCache markets;

  /// The cache of behaviors.
  final BehaviorCache behaviors;

  /// The cache of factions.
  final FactionCache factions;

  /// The cache of charting data.
  final ChartingCache charting;

  /// The cache of jump routes.
  final JumpCache jumps = JumpCache();

  /// Load the cache from disk and network.
  static Future<Caches> load(
    FileSystem fs,
    Api api, {
    required Future<http.Response> Function(Uri uri) httpGet,
  }) async {
    final agent = await AgentCache.load(api, fs: fs);
    final prices = await MarketPrices.load(fs);
    // Intentionally do not load ships from disk (they change too often).
    final ships = await ShipCache.load(api, fs: fs, forceRefresh: true);
    final shipyard = await ShipyardPrices.load(fs);
    final surveys = await SurveyData.load(fs);
    final systems = await SystemsCache.load(fs, httpGet: httpGet);
    final systemConnectivity = SystemConnectivity.fromSystemsCache(systems);
    final transactions = await TransactionLog.load(fs);
    final charting = ChartingCache.load(fs);
    final waypoints = WaypointCache(api, systems, charting);
    final markets = MarketCache(waypoints);
    // Intentionally force refresh contracts in case we've been offline.
    final contracts = await ContractCache.load(api, fs: fs, forceRefresh: true);
    final behaviors = BehaviorCache.load(fs);
    // Intentionally load factions from disk (they never change).
    final factions = await FactionCache.load(api, fs: fs);

    // Save out the caches we never modify so we don't have to load them again.
    await factions.save();

    // We rarely modify contracts, so save them out here too.
    await contracts.save();

    return Caches._(
      agent: agent,
      marketPrices: prices,
      ships: ships,
      shipyardPrices: shipyard,
      surveys: surveys,
      systems: systems,
      systemConnectivity: systemConnectivity,
      transactions: transactions,
      waypoints: waypoints,
      markets: markets,
      contracts: contracts,
      behaviors: behaviors,
      factions: factions,
      charting: charting,
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
    await ships.save();
  }
}
