import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/contract_trader.dart';
import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/queries.dart';

/// The context for a behavior.
class BehaviorContext {
  /// Create a BehaviorContext
  BehaviorContext(
    this.api,
    this.db,
    this.priceData,
    this.ship,
    this.agent,
    this.waypointCache,
    this.marketCache,
    this.behaviorManager,
    this.contract,
    this.maybeGoods,
  );

  /// Handle to the API clients.
  final Api api;

  /// Handle to the database.
  final DataStore db;

  /// The current price data.
  final PriceData priceData;

  /// The ship we are controlling.
  final Ship ship;

  /// The agent object.
  final Agent agent;

  /// The cache of waypoints.
  final WaypointCache waypointCache;

  /// The cache of markets.
  final MarketCache marketCache;

  /// The behavior manager.
  final BehaviorManager behaviorManager;

  /// The current contract.
  final Contract? contract;

  /// The goods we are delivering.
  final ContractDeliverGood? maybeGoods;

  /// Load the behavior state for the given ship.
  Future<BehaviorState> loadBehaviorState() async =>
      behaviorManager.getBehavior(ship.symbol);
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
    case Behavior.contractTrader:
      return advanceContractTrader(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.behaviorManager,
        ctx.contract,
        ctx.maybeGoods,
      );
    case Behavior.arbitrageTrader:
      return advanceArbitrageTrader(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.behaviorManager,
      );
    case Behavior.miner:
      return advanceMiner(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.waypointCache,
        ctx.behaviorManager,
      );

    case Behavior.explorer:
      return advanceExporer(
        ctx.api,
        ctx.db,
        ctx.priceData,
        ctx.agent,
        ctx.ship,
        ctx.waypointCache,
        ctx.marketCache,
        ctx.behaviorManager,
      );
  }
}