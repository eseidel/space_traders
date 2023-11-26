import 'package:types/types.dart';

/// Class for holding our hard-coded configuration values.
class Config {
  /// Our ship buy plan for computeNextShipToBuy.
  final buyPlan = [
    ShipType.LIGHT_SHUTTLE,
    ShipType.MINING_DRONE,
    ShipType.SIPHON_DRONE,
    ShipType.SURVEYOR,
    ShipType.LIGHT_SHUTTLE,
    ShipType.MINING_DRONE,
    ShipType.SIPHON_DRONE,
    ShipType.SURVEYOR,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    ShipType.MINING_DRONE,
    ShipType.SURVEYOR,
    for (int i = 0; i < 15; i++) ShipType.LIGHT_HAULER,
  ];

  /// A list of which haulers should be used as miner haulers.
  // This should instead be some min count of light-haulers before we
  // start making miner haulers, and then some max count of miner haulers?
  final minerHaulerSymbols = <String>['12', '13', '14', '18', '1E']
      .map((s) => ShipSymbol.fromString('ESEIDEL-$s'));

  /// Used as a fallback for constructin Behaviors if there isn't explicit
  /// logic in getJobForShip.
  final behaviorsByFleetRole = {
    FleetRole.command: [
      // Will only trade if we can make 6/s or more.
      // There are commonly 20c/s trades in the starting system, and at
      // the minimum we want to accept the contract.
      // Might want to consider limiting to short trades (< 5 mins) to avoid
      // tying up capital early.
      Behavior.trader,
      // Early on the command ship makes about 5c/s vs. ore hounds making
      // 6c/s. It's a better surveyor than miner. Especially when enabling
      // mining drones.
      // if (shipCount > 3 && shipCount < 10) Behavior.surveyor,
      // Mining is more profitable than siphoning I think?
      Behavior.miner,
      Behavior.siphoner,
    ],
    FleetRole.trader: [
      Behavior.trader,
      // Would rather have Haulers idle, than explore if fuel costs are high.
      // Behavior.explorer,
    ],
    FleetRole.miner: [Behavior.miner],
    FleetRole.surveyor: [Behavior.surveyor],
    FleetRole.siphoner: [Behavior.siphoner],
    FleetRole.explorer: [Behavior.explorer],
  };

// We could put some "total value" on the idea of the gate being open
  // and change that over time to encourage building it sooner.
  // For now we're just hard-coding a price for each needed good.
  /// Used by sellOppsForConstruction to determine what SellOpps for
  /// construction materials should be priced at.
  final constructionMaxPurchasePrice = {
    TradeSymbol.FAB_MATS: 4000,
    TradeSymbol.ADVANCED_CIRCUITRY: 13000,
  };

  /// Used by shouldBuyShip to make sure we don't buy a ship when it would
  /// affect our ability to trade.
  final shipBuyBufferForTrading = 100000;

  /// Used by _minimumFloatRequired to ensure we always have enough to complete
  /// a contract and don't just dump money into something we can't finish.
  final contractMinFloat = 100000;

  /// Used by _minimumBufferRequired to ensure we over-estimate how much we
  /// need in reserve for contract completion.
  final contractMinBuffer = 20000;
}

/// Our global configuration object.
final config = Config();
