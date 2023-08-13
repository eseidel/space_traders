import 'package:cli/cache/behavior_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('BehaviorCache roundtrip', () async {
    final fs = MemoryFileSystem.test();
    const shipSymbol = ShipSymbol('S', 1);
    final state = BehaviorState(shipSymbol, Behavior.buyShip);
    final route = RoutePlan(
      fuelCapacity: 100,
      shipSpeed: 20,
      actions: [
        RouteAction(
          startSymbol: WaypointSymbol.fromString('S-E-A'),
          endSymbol: WaypointSymbol.fromString('S-E-B'),
          type: RouteActionType.navCruise,
          duration: 30,
        )
      ],
      fuelUsed: 20,
    );
    state.routePlan = route;
    final deal = Deal.test(
      sourceSymbol: WaypointSymbol.fromString('S-A-B'),
      destinationSymbol: WaypointSymbol.fromString('S-A-C'),
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    state.deal = CostedDeal(
      deal: deal,
      transactions: [],
      startTime: DateTime.timestamp(),
      route: route,
      cargoSize: 100,
      costPerFuelUnit: 100,
    );
    final stateByShipSymbol = {
      shipSymbol: state,
    };
    BehaviorCache(stateByShipSymbol, fs: fs).save();
    final loaded = BehaviorCache.load(fs);
    expect(
      loaded.getBehavior(shipSymbol)!.behavior,
      stateByShipSymbol[shipSymbol]!.behavior,
    );
  });
}
