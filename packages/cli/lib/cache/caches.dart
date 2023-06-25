import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/shipyard_prices.dart';
import 'package:cli/cache/surveys.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:file/file.dart';

export 'package:cli/api.dart';
export 'package:cli/cache/agent_cache.dart';
export 'package:cli/cache/market_prices.dart';
export 'package:cli/cache/ship_cache.dart';
export 'package:cli/cache/shipyard_prices.dart';
export 'package:cli/cache/surveys.dart';
export 'package:cli/cache/systems_cache.dart';
export 'package:cli/cache/transactions.dart';
export 'package:cli/cache/waypoint_cache.dart';
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
    required this.transactions,
    required this.waypoints,
    required this.markets,
  });

  /// The agent cache.
  final AgentCache agent;

  /// The historical market price data.
  final MarketPrices marketPrices;

  /// The ship cache.
  final ShipCache ships;

  /// The historical shipyard prices.
  final ShipyardPrices shipyardPrices;

  /// The survey data.
  final SurveyData surveys;

  /// The cache of systems.
  final SystemsCache systems;

  /// The transaction log.
  final TransactionLog transactions;

  /// The cache of waypoints.
  final WaypointCache waypoints;

  /// The cache of markets.
  final MarketCache markets;

  /// Load the cache from disk and network.
  static Future<Caches> load(FileSystem fs, Api api) async {
    final agent = await AgentCache.load(api);
    final prices = await MarketPrices.load(fs);
    final ships = await ShipCache.load(api);
    final shipyard = await ShipyardPrices.load(fs);
    final surveys = await SurveyData.load(fs);
    final systems = await SystemsCache.load(fs);
    final transactions = await TransactionLog.load(fs);
    final waypoints = WaypointCache(api, systems);
    final markets = MarketCache(waypoints);
    return Caches._(
      agent: agent,
      marketPrices: prices,
      ships: ships,
      shipyardPrices: shipyard,
      surveys: surveys,
      systems: systems,
      transactions: transactions,
      waypoints: waypoints,
      markets: markets,
    );
  }
}
