import 'package:cli/cache/behavior_snapshot.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockBehaviorStore extends Mock implements BehaviorStore {}

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

void main() {
  test('BehaviorsTimeouts.isDisabledForShip', () async {
    final db = _MockDatabase();

    final behaviorStore = _MockBehaviorStore();
    when(() => db.behaviors).thenReturn(behaviorStore);

    registerFallbackValue(BehaviorState.fallbackValue());
    registerFallbackValue(const ShipSymbol.fallbackValue());
    when(() => behaviorStore.upsert(any())).thenAnswer((_) async {
      return;
    });
    when(() => behaviorStore.delete(any())).thenAnswer((_) async {});

    final behaviorTimeouts = BehaviorTimeouts();
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    expect(
      behaviorTimeouts.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    when(
      () => behaviorStore.get(shipSymbol),
    ).thenAnswer((_) async => BehaviorState(shipSymbol, Behavior.trader));

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () async => behaviorTimeouts.disableBehaviorForShip(
        db,
        ship,
        'why',
        const Duration(hours: 1),
      ),
    );
    final ship2 = _MockShip();
    const shipSymbol2 = ShipSymbol('S', 2);
    when(() => ship2.symbol).thenReturn(shipSymbol2);
    expect(
      behaviorTimeouts.isBehaviorDisabledForShip(ship, Behavior.trader),
      true,
    );
    expect(
      behaviorTimeouts.isBehaviorDisabledForShip(ship2, Behavior.trader),
      false,
    );
  });
}
