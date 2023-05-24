import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/contract_trader.dart';
import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/prices.dart';

/// Advance the behavior of the given ship.
/// Returns the time at which the behavior should be advanced again
/// or null if can be advanced immediately.
Future<DateTime?> advanceShipBehavior(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  List<Waypoint> systemWaypoints,
  BehaviorState behavior,
  Contract? contract,
  ContractDeliverGood? maybeGoods,
) async {
  switch (behavior.behavior) {
    case Behavior.contractTrader:
      return advanceContractTrader(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
        contract!,
        maybeGoods!,
      );
    case Behavior.arbitrageTrader:
      return advanceArbitrageTrader(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
      );
    case Behavior.miner:
      return advanceMiner(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
      );

    case Behavior.explorer:
      return advanceExporer(
        api,
        db,
        priceData,
        agent,
        ship,
        systemWaypoints,
      );
  }
}
