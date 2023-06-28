import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/behavior_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockBehhaviorCache extends Mock implements BehaviorCache {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShip extends Mock implements Ship {}

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

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

  test('CentralCommand.otherExplorerSystems', () async {
    final fs = MemoryFileSystem.test();
    final behaviorCache = await BehaviorCache.load(fs);
    final shipCache = _MockShipCache();
    final centralCommand = CentralCommand(behaviorCache, shipCache);
    final shipA = _MockShip();
    final shipNavA = _MockShipNav();
    when(() => shipA.symbol).thenReturn('A');
    when(() => shipNavA.systemSymbol).thenReturn('S-A');
    when(() => shipA.nav).thenReturn(shipNavA);
    await centralCommand.setBehavior(
      'A',
      BehaviorState('A', Behavior.explorer),
    );
    await centralCommand.setDestination(shipA, 'S-A-W');
    final shipB = _MockShip();
    when(() => shipB.symbol).thenReturn('B');
    final shipNavB = _MockShipNav();
    when(() => shipNavB.systemSymbol).thenReturn('S-C');
    when(() => shipB.nav).thenReturn(shipNavB);
    await centralCommand.setBehavior(
      'B',
      BehaviorState('B', Behavior.explorer),
    );
    await centralCommand.setDestination(shipB, 'S-B-W');
    when(() => shipCache.ship('B')).thenReturn(shipB);

    final otherSystems = centralCommand.otherExplorerSystems('A');
    expect(otherSystems, ['S-B']); // From destination
    await centralCommand.reachedDestination(shipB);
    final otherSystems2 = centralCommand.otherExplorerSystems('A');
    expect(otherSystems2, ['S-C']); // From nav.systemSymbol
    await centralCommand.completeBehavior('B');
    final otherSystems3 = centralCommand.otherExplorerSystems('A');
    expect(otherSystems3, <String>[]);
  });
}
