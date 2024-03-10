import 'package:cli/cache/behavior_snapshot.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

void main() {
  test('BehaviorsTimeouts.isDisabledForShip', () async {
    final db = _MockDatabase();
    registerFallbackValue(BehaviorState.fallbackValue());
    registerFallbackValue(const ShipSymbol.fallbackValue());
    when(() => db.setBehaviorState(any())).thenAnswer((_) async {});
    when(() => db.deleteBehaviorState(any())).thenAnswer((_) async {});

    final behaviorTimeouts = BehaviorTimeouts();
    final ship = _MockShip();
    const s1 = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(s1);
    when(() => ship.symbolString).thenReturn(s1.toJson());
    when(() => ship.emojiName).thenReturn('🛸');
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    expect(
      behaviorTimeouts.isBehaviorDisabledForShip(ship, Behavior.trader),
      false,
    );

    when(() => db.behaviorStateBySymbol(s1)).thenAnswer(
      (_) async => BehaviorState(s1, Behavior.trader),
    );

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
    final s2 = ShipSymbol.fromString('S-2');
    when(() => ship2.symbol).thenReturn(s2);
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
