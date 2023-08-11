import 'package:cli/behavior/advance.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockBehaviorCache extends Mock implements BehaviorCache {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('advanceShipBehavior idle does not spin hot', () async {
    final api = _MockApi();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final db = _MockDatabase();
    final caches = _MockCaches();
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final behaviorCache = _MockBehaviorCache();
    when(() => caches.behaviors).thenReturn(behaviorCache);
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);

    final behaviorState = BehaviorState(shipSymbol, Behavior.idle);
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.loadBehaviorState(ship))
        .thenAnswer((_) => Future.value(behaviorState));
    final logger = _MockLogger();
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
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();

    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    final caches = _MockCaches();
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);

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

    when(() => centralCommand.loadBehaviorState(ship)).thenAnswer(
      (_) => Future.value(BehaviorState(shipSymbol, Behavior.idle)),
    );

    final logger = _MockLogger();

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
    verify(() => logger.info('🛸#1  ✈️  to S-A-W, 1s left')).called(1);
  });
}
