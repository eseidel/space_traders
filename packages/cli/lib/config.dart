import 'package:types/types.dart';

/// The default max age for our caches is 3 days.
/// This is used as a default argument and must be const.
const defaultMaxAge = Duration(days: 3);

/// Which game phase are we in.
enum GamePhase with EnumIndexOrdering {
  /// Initially just buying haulers and getting trading going.
  bootstrap,

  /// Focused on building the jumpgate.
  construction,

  /// Focused on explorating the galaxy to find better ships.
  exploration,
}

/// Which phase are we in.
// TODO(eseidel): Make this dynamic.
const gamePhase = GamePhase.exploration;

/// Class for holding our hard-coded configuration values.
class Config {
  // TODO(eseidel): This should be configured at runtime.
  /// The symbol of the agent we are controlling.
  final String agentSymbol = 'ESEIDEL';

  /// Whether or not we should enable mining behaviors.
  final bool enableMining = gamePhase < GamePhase.exploration;

  /// Controls how many loops we run of ships before doing our central
  /// planning (assigning ships to squads, planning mounts, etc.)
  final int centralPlanningInterval = 20;

  /// Used to slow down charters and have them spend less money on jumps.
  bool chartAsteroidsByDefault = false;

  /// findBetterTradeLocation is too slow when we have lots of systems
  bool disableFindBetterTradeLocation = true;

  /// The number of requests per second allowed by the api.
  /// Version 2.1 allows:
  /// - 2 requests per second
  /// - plus 30 requests over a 60 second burst
  /// 2 * 60 + 30 = 150 requests per minute / 60 = 2.5 requests per second
  /// https://docs.spacetraders.io/api-guide/rate-limits
  double targetRequestsPerSecond = 2.5;

  /// Our ship buy plan for computeNextShipToBuy.
  final buyPlan = [
    ShipType.LIGHT_HAULER,
    ShipType.LIGHT_HAULER,
    ShipType.LIGHT_HAULER,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    ShipType.SIPHON_DRONE,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    ShipType.MINING_DRONE,
    ShipType.MINING_DRONE,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    for (int i = 0; i < 13; i++) ShipType.LIGHT_HAULER,
    // Only buy after gate opens.
    for (int i = 0; i < 20; i++) ShipType.PROBE,
    for (int i = 0; i < 10; i++) ShipType.REFINING_FREIGHTER,
    // Only buy with 3m in cash?
    for (int i = 0; i < 20; i++) ShipType.PROBE,
    // Only buy with 3m in cash?
    for (int i = 0; i < 20; i++) ShipType.EXPLORER,
  ];

  // TODO(eseidel): Should be some dynamic min count of light-haulers before we
  // start making miner haulers, and then some max count of miner haulers?
  /// Number of haulers to use as miner haulers.
  int get minerHaulerCount => (gamePhase == GamePhase.construction) ? 6 : 0;

  /// Used as a fallback for constructing Behaviors if there isn't explicit
  /// logic in getJobForShip.
  final behaviorsByFleetRole = {
    FleetRole.command: [
      // Will only trade if we can make 6/s or more.
      // There are commonly 20c/s trades in the starting system, and at
      // the minimum we want to accept the contract.
      // Might want to consider limiting to short trades (< 5 mins) to avoid
      // tying up capital early.
      Behavior.trader,
      // Early game we can use the command ship to explore if needed.
      // This is perfered over mining and siphoning in case those are far away
      // on the assumption the command ship should be trading early and all
      // it's missing is price data to do so.
      // Behavior.charter,
      // Early on the command ship makes about 5c/s vs. ore hounds making
      // 6c/s. It's a better surveyor than miner. Especially when enabling
      // mining drones.
      // if (shipCount > 3 && shipCount < 10) Behavior.surveyor,
      // Mining is more profitable than siphoning I think?
      Behavior.miner,
      Behavior.siphoner,
    ],
    FleetRole.trader: [Behavior.trader],
    FleetRole.explorer: [Behavior.trader],
    // TODO(eseidel): I don't think these do anything anymore:
    // FleetRole.miner: [Behavior.miner],
    // FleetRole.surveyor: [Behavior.surveyor],
    FleetRole.siphoner: [Behavior.siphoner],
  };

  // We could put some "total value" on the idea of the gate being open
  // and change that over time to encourage building it sooner.
  // For now we're just hard-coding a price for each needed good.
  /// Used by sellOppsForConstruction to determine what SellOpps for
  /// construction materials should be priced at.
  final constructionMaxPurchasePrice = {
    TradeSymbol.FAB_MATS: 3000,
    TradeSymbol.ADVANCED_CIRCUITRY: 9000,
  };

  /// Used by _computeActiveConstruction to compute if we should be doing
  /// construction yet or not.
  final constructionMinCredits = 1000000;

  /// Used by shouldBuyShip to make sure we don't buy a ship when it would
  /// affect our ability to trade.
  // TODO(eseidel): Make this vary based on how many traders we have.
  final shipBuyBufferForTrading = 500000;

  /// Used by _minimumFloatRequired to ensure we always have enough to complete
  /// a contract and don't just dump money into something we can't finish.
  final contractMinFloat = 100000;

  /// Used by _minimumBufferRequired to ensure we over-estimate how much we
  /// need in reserve for contract completion.
  final contractMinBuffer = 20000;

  /// Maximum distance for ExtractionScores we will consider.
  final maxExtractionDeliveryDistance = 160;

  /// Assumed fuel cost when we don't have price information.
  final defaultFuelCost = 100;

  /// Assumed antimatter cost when we don't have price information.
  final defaultAntimatterCost = 10000;

  /// Initial max age for price data in any given system.
  final defaultMaxAgeForPriceData = const Duration(days: 3);

  /// Allow multiple ships to be assigned to the same construction job.
  // This is mostly a hack around the fact that our construction can get
  // stuck with auto-drifting ships holding the lock for 6hrs.
  // This can cause cash-flow problems early on, since many ships will try
  // to buy the high priced materials at once.
  final allowParallelConstructionDelivery = true;

  /// The amount of credits to subsidize each unit of construction materials.
  int subsidyForSupplyLevel(SupplyLevel supplyLevel) {
    switch (supplyLevel) {
      case SupplyLevel.ABUNDANT:
        return 0;
      case SupplyLevel.HIGH:
        return 50;
      case SupplyLevel.MODERATE:
        return 100;
      case SupplyLevel.LIMITED:
        return 150;
      case SupplyLevel.SCARCE:
        return 200;
    }
    throw ArgumentError('Unknown supplyLevel: $supplyLevel');
  }

  /// Max number of jumps we allow a charter to plan for at once.
  final charterMaxJumps = 5;

  /// Minimum number of markets in a system before we bother assigning a
  /// system watcher.
  final minMarketsForSystemWatcher = 5;

  /// The threshold at which we consider a ship to be "critical" on fuel.
  /// meaning we will refuel even if it's too expensive.
  final fuelCriticalThreshold = 0.3;

  /// The threshold at which we will stop refueling a ship if too expensive.
  final fuelWarningMarkup = 5.0;

  /// Maximum markup we will tolerate when refueling (otherwise we will drift).
  final fuelMaxMarkup = 10.0;
}

/// Our global configuration object.
final config = Config();
