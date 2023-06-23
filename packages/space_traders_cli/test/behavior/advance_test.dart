import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/advance.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockBehaviorContext extends Mock implements BehaviorContext {}

class _MockBehaviorManager extends Mock implements BehaviorManager {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('advanceShipBehavior idle does not spin hot', () async {
    final ctx = _MockBehaviorContext();
    final api = _MockApi();
    final systemsCache = _MockSystemsCache();
    final behaviorManager = _MockBehaviorManager();
    when(() => ctx.api).thenReturn(api);
    when(() => ctx.systemsCache).thenReturn(systemsCache);
    when(() => ctx.behaviorManager).thenReturn(behaviorManager);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);

    final behaviorState = BehaviorState(Behavior.idle);
    when(ctx.loadBehaviorState)
        .thenAnswer((invocation) => Future.value(behaviorState));
    when(() => behaviorManager.getBehavior(ship)).thenAnswer(
      (invocation) => Future.value(behaviorState),
    );

    when(() => ctx.ship).thenReturn(ship);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(ctx, getNow: getNow),
    );
    expect(waitUntil, isNotNull);
  });

  test('advanceShipBehavior in transit', () async {
    final api = _MockApi();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final behaviorManager = _MockBehaviorManager();

    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    final ctx = _MockBehaviorContext();
    when(() => ctx.api).thenReturn(api);
    when(() => ctx.systemsCache).thenReturn(systemsCache);
    when(() => ctx.behaviorManager).thenReturn(behaviorManager);

    final now = DateTime(2021);
    final arrivalTime = now.add(const Duration(seconds: 1));
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNav.waypointSymbol).thenReturn('W');
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNavRoute.arrival).thenReturn(arrivalTime);
    when(ctx.loadBehaviorState)
        .thenAnswer((invocation) => Future.value(BehaviorState(Behavior.idle)));
    when(() => ctx.ship).thenReturn(ship);

    final logger = _MockLogger();

    final waitUntil = await runWithLogger(
      logger,
      () => advanceShipBehavior(ctx, getNow: getNow),
    );
    expect(waitUntil, arrivalTime);
    verify(() => logger.info('🛸#S  ✈️  to W, 00:00:01 left')).called(1);
  });
}
