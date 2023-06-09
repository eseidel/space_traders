import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/jump_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockApi extends Mock implements Api {}

class _MockShip extends Mock implements Ship {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

void main() {
  test('continueNavigationIfNeeded changes ship.nav.status', () async {
    final api = _MockApi();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final jumpCache = JumpCache();
    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    final centralCommand = _MockCentralCommand();

    /// The behavior doesn't matter, just needs to have a null destination.
    when(() => centralCommand.getBehavior('S'))
        .thenAnswer((_) => BehaviorState('S', Behavior.idle));

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = _MockLogger();
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
        systemConnectivity,
        jumpCache,
        centralCommand,
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
        systemConnectivity,
        jumpCache,
        centralCommand,
        getNow: getNow,
      ),
    );
    expect(afterResult.shouldReturn(), true);
    expect(afterResult.waitTime, after);
    // This should be 0, I must not be understanding mocktail correctly.
    verifyNever(() => shipNav.status = ShipNavStatus.IN_ORBIT);
  });
}
