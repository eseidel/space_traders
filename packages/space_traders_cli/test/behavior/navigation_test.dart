import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class MockApi extends Mock implements Api {}

class MockShip extends Mock implements Ship {}

class MockSystemsCache extends Mock implements SystemsCache {}

class MockBehaviorManager extends Mock implements BehaviorManager {}

class MockLogger extends Mock implements Logger {}

class MockShipNav extends Mock implements ShipNav {}

class MockShipNavRoute extends Mock implements ShipNavRoute {}

void main() {
  test('continueNavigationIfNeeded changes ship.nav.status', () async {
    final api = MockApi();
    final ship = MockShip();
    final systemsCache = MockSystemsCache();
    final behaviorManager = MockBehaviorManager();
    final shipNav = MockShipNav();
    final shipNavRoute = MockShipNavRoute();
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);

    /// The behavior doesn't matter, just needs to have a null destination.
    when(() => behaviorManager.getBehavior(ship))
        .thenAnswer((invocation) => Future.value(BehaviorState(Behavior.idle)));

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = MockLogger();
    // The case when the arrival time is in the past.
    final before = now.subtract(const Duration(milliseconds: 1));
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNavRoute.arrival).thenReturn(before);
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNav.waypointSymbol).thenReturn('A-B-C');

    final beforeResult = await runWithLogger(
      logger,
      () => continueNavigationIfNeeded(
        api,
        ship,
        systemsCache,
        behaviorManager,
        getNow: getNow,
      ),
    );
    expect(beforeResult.shouldReturn(), false);
    expect(() => beforeResult.waitTime, throwsStateError);
    verify(() => shipNav.status = ShipNavStatus.IN_ORBIT).called(1);

    // The case when the arrival time is in the future.
    reset(ship.nav);
    final after = now.add(const Duration(milliseconds: 1));
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNavRoute.arrival).thenReturn(after);
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNav.waypointSymbol).thenReturn('A-B-C');

    final afterResult = await runWithLogger(
      logger,
      () => continueNavigationIfNeeded(
        api,
        ship,
        systemsCache,
        behaviorManager,
        getNow: getNow,
      ),
    );
    expect(afterResult.shouldReturn(), true);
    expect(afterResult.waitTime, after);
    // This should be 0, I must not be understanding mocktail correctly.
    verifyNever(() => shipNav.status = ShipNavStatus.IN_ORBIT);
  });
}
