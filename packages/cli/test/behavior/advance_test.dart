import 'package:cli/behavior/advance.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

void main() {
  test('advanceShipBehavior idle does not spin hot', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final caches = mockCaches();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);

    final centralCommand = _MockCentralCommand();
    final logger = _MockLogger();

    when(() => db.behaviorStateBySymbol(shipSymbol))
        .thenAnswer((_) async => null);

    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, isNotNull);
  });

  test('advanceShipBehavior in transit', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();

    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    final caches = mockCaches();
    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);

    final now = DateTime(2021);
    final arrivalTime = now.add(const Duration(seconds: 1));
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNavRoute.arrival).thenReturn(arrivalTime);
    final centralCommand = _MockCentralCommand();

    final logger = _MockLogger();

    when(() => db.behaviorStateBySymbol(shipSymbol))
        .thenAnswer((_) async => null);

    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, arrivalTime);
    verify(() => logger.info('🛸#1  ✈️  to A-W, 1s left')).called(1);
  });
}
