import 'package:cli/behavior/advance.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockBehaviorCache extends Mock implements BehaviorCache {}

void main() {
  test('advanceShipBehavior idle does not spin hot', () async {
    final api = _MockApi();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final caches = _MockCaches();
    final jumpCache = JumpCache();
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    when(() => caches.jumps).thenReturn(jumpCache);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final behaviorCache = _MockBehaviorCache();
    when(() => caches.behaviors).thenReturn(behaviorCache);

    final behaviorState = BehaviorState('S', Behavior.idle);
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.loadBehaviorState(ship))
        .thenAnswer((_) => Future.value(behaviorState));
    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(
        api,
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
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();

    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    final caches = _MockCaches();
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final jumpCache = JumpCache();
    when(() => caches.jumps).thenReturn(jumpCache);

    final now = DateTime(2021);
    final arrivalTime = now.add(const Duration(seconds: 1));
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNav.waypointSymbol).thenReturn('W');
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNavRoute.arrival).thenReturn(arrivalTime);
    final centralCommand = _MockCentralCommand();

    when(() => centralCommand.loadBehaviorState(ship))
        .thenAnswer((_) => Future.value(BehaviorState('S', Behavior.idle)));

    final logger = _MockLogger();

    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(
        api,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, arrivalTime);
    verify(() => logger.info('🛸#S  ✈️  to W, 00:00:01 left')).called(1);
  });
}
