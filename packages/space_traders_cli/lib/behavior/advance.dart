import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/buy_ship.dart';
import 'package:space_traders_cli/behavior/contract_trader.dart';
import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/surveys.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';

/// The context for a behavior.
class BehaviorContext {
  /// Create a BehaviorContext
  BehaviorContext(
    this.api,
    this.db,
    this.priceData,
    this.shipyardPrices,
    this.shipCache,
    this.agent,
    this.systemsCache,
    this.waypointCache,
    this.marketCache,
    this.behaviorManager,
    this.surveyData,
    this.transactions,
    this.ship,
  );

  /// Handle to the API clients.
  final Api api;

  /// Handle to the database.
  final DataStore db;

  /// The historical market price data.
  final PriceData priceData;

  /// The historical shipyard prices.
  final ShipyardPrices shipyardPrices;

  /// The ShipCache.
  final ShipCache shipCache;

  /// The ship we are controlling.
  final Ship ship;

  /// The agent object.
  final Agent agent;

  /// The cache of systems.
  final SystemsCache systemsCache;

  /// The cache of waypoints.
  final WaypointCache waypointCache;

  /// The cache of markets.
  final MarketCache marketCache;

  /// The behavior manager.
  final BehaviorManager behaviorManager;

  /// The survey data.
  final SurveyData surveyData;

  /// The transaction log.
  final TransactionLog transactions;

  /// Load the behavior state for the given ship.
  Future<BehaviorState> loadBehaviorState() async =>
      behaviorManager.getBehavior(ship);
}

/// Advance the behavior of the given ship.
/// Returns the time at which the behavior should be advanced again
/// or null if can be advanced immediately.
Future<DateTime?> advanceShipBehavior(
  BehaviorContext ctx,
) async {
  final behavior = await ctx.loadBehaviorState();
  // shipDetail(ship, 'Advancing behavior: ${behavior.behavior.name}');
  switch (behavior.behavior) {
    case Behavior.buyShip:
      return advanceBuyShip(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.shipyardPrices,
        ctx.agent,
        ctx.ship,
        ctx.systemsCache,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.transactions,
        ctx.behaviorManager,
        ctx.surveyData,
      );
    case Behavior.contractTrader:
      return advanceContractTrader(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.systemsCache,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.transactions,
        ctx.behaviorManager,
      );
    case Behavior.arbitrageTrader:
      return advanceArbitrageTrader(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.systemsCache,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.transactions,
        ctx.behaviorManager,
      );
    case Behavior.miner:
      return advanceMiner(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.systemsCache,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.transactions,
        ctx.behaviorManager,
        ctx.surveyData,
      );

    case Behavior.explorer:
      return advanceExporer(
        ctx.api,
        ctx.db,
        ctx.transactions,
        ctx.priceData,
        ctx.shipyardPrices,
        ctx.agent,
        ctx.ship,
        ctx.systemsCache,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.behaviorManager,
      );
    case Behavior.idle:
      shipDetail(ctx.ship, 'Idling');
      return null;
  }
}
