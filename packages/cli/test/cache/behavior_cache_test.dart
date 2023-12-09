import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

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
          seconds: 30,
          fuelUsed: 10,
        ),
      ],
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
      costPerAntimatterUnit: 10000,
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

  test('BehaviorCache.isDisabledForShip', () async {
    final fs = MemoryFileSystem.test();
    final behaviorCache = BehaviorCache.load(fs);
    final ship = _MockShip();
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    expect(
      behaviorCache.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    behaviorCache.setBehavior(
      shipSymbol,
      BehaviorState(shipSymbol, Behavior.trader),
    );

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => behaviorCache.disableBehaviorForShip(
        ship,
        'why',
        const Duration(hours: 1),
      ),
    );
    final ship2 = _MockShip();
    when(() => ship2.symbol).thenReturn('S-2');
    expect(
      behaviorCache.isBehaviorDisabledForShip(ship, Behavior.trader),
      true,
    );
    expect(
      behaviorCache.isBehaviorDisabledForShip(ship2, Behavior.trader),
      false,
    );
  });
}
