import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockBehhaviorCache extends Mock implements BehaviorCache {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShip extends Mock implements Ship {}

class _MockLogger extends Mock implements Logger {}

void main() {
  test('CentralCommand.isEnabled', () async {
    final behaviorCache = _MockBehhaviorCache();
    final shipCache = _MockShipCache();
    final centralCommand = CentralCommand(behaviorCache, shipCache);
    expect(centralCommand.isEnabled(Behavior.trader), true);

    when(() => behaviorCache.deleteBehavior('S'))
        .thenAnswer((_) => Future.value());

    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S');
    final logger = _MockLogger();

    await runWithLogger(
      logger,
      () async => centralCommand.disableBehavior(
        ship,
        Behavior.trader,
        'why',
        const Duration(hours: 1),
      ),
    );
    expect(centralCommand.isEnabled(Behavior.trader), false);
  });

  test('CentralCommand.behaviorFor', () async {
    final behaviorCache = _MockBehhaviorCache();
    final shipCache = _MockShipCache();
    final centralCommand = CentralCommand(behaviorCache, shipCache);
    final ship = _MockShip();
    when(() => ship.registration).thenReturn(
      ShipRegistration(
        name: 'S',
        factionSymbol: 'F',
        role: ShipRole.CARRIER,
      ),
    );
    final logger = _MockLogger();
    // Ship types we've never heard of, just return idle.
    final behavior =
        runWithLogger(logger, () => centralCommand.behaviorFor(ship));
    expect(behavior, Behavior.idle);
  });
}
