import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class MockShip extends Mock implements Ship {}

class MockBehaviorContext extends Mock implements BehaviorContext {}

class MockLogger extends Mock implements Logger {}

void main() {
  test('advanceShipBehavior idle does not spin hot', () async {
    final ctx = MockBehaviorContext();
    final ship = MockShip();
    when(() => ship.symbol).thenReturn('ship-id');
    when(ctx.loadBehaviorState)
        .thenAnswer((invocation) => Future.value(BehaviorState(Behavior.idle)));
    when(() => ctx.ship).thenReturn(ship);

    final logger = MockLogger();
    final waitUntil =
        await runWithLogger(logger, () => advanceShipBehavior(ctx));
    expect(waitUntil, isNotNull);
  });
}
