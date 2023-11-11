import 'package:cli/api.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
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
  test('continueNavigationIfNeeded changes ship.nav.status', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);

    /// The behavior doesn't matter, just needs to have a null destination.
    final state = BehaviorState(shipSymbol, Behavior.idle);

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
        db,
        centralCommand,
        caches,
        ship,
        state,
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
        db,
        centralCommand,
        caches,
        ship,
        state,
        getNow: getNow,
      ),
    );
    expect(afterResult.shouldReturn(), true);
    expect(afterResult.waitTime, after);
    verifyNever(() => shipNav.status = ShipNavStatus.IN_ORBIT);
  });

  // test('continueNavigationIfNeeded sets cooldown after jump', () async {
  //   final api = _MockApi();
  //   final fleetApi = _MockFleetApi();
  //   when(() => api.fleet).thenReturn(fleetApi);
  //   final systemsCache = _MockSystemsCache();
  //   final shipCache = _MockShipCache();
  //   final shipNav = _MockShipNav();
  //   const shipSymbol = ShipSymbol('S', 1);
  //   // We use a real Ship to allow setting/reading from cooldown.
  //   final ship = Ship(
  //     symbol: shipSymbol.symbol,
  //     cooldown: Cooldown(
  //       shipSymbol: shipSymbol.symbol,
  //       totalSeconds: 0,
  //       remainingSeconds: 0,
  //     ),
  //     nav: shipNav,
  //     reactor: _MockShipReactor(),
  //     engine: _MockShipEngine(),
  //     registration: _MockShipRegistration(),
  //     frame: _MockShipFrame(),
  //     crew: _MockShipCrew(),
  //     cargo: _MockShipCargo(),
  //     fuel: _MockShipFuel(),
  //   );

  //   final centralCommand = _MockCentralCommand();
  //   when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);

  //   /// The behavior doesn't matter, just needs to have a null destination.
  //   final state = BehaviorState(shipSymbol, Behavior.idle);

  //   final now = DateTime(2021);
  //   DateTime getNow() => now;
  //   final logger = _MockLogger();

  //   final startSymbol = WaypointSymbol.fromString('A-B-C');
  //   final endSymbol = WaypointSymbol.fromString('D-E-F');

  //   when(() => shipNav.waypointSymbol).thenReturn(startSymbol.waypoint);
  //   when(() => shipNav.systemSymbol).thenReturn(startSymbol.system);

  //   state.routePlan = RoutePlan(
  //     fuelCapacity: 100,
  //     shipSpeed: 100,
  //     actions: [
  //       RouteAction(
  //         startSymbol: startSymbol,
  //         endSymbol: endSymbol,
  //         type: RouteActionType.jump,
  //         duration: 100,
  //       ),
  //     ],
  //     fuelUsed: 100,
  //   );
  //   final reactorExpiry = now.add(const Duration(seconds: 100));

  //   when(() => systemsCache.waypointFromSymbol(startSymbol)).thenReturn(
  //     SystemWaypoint(
  //       symbol: startSymbol.waypoint,
  //       type: WaypointType.ASTEROID_FIELD,
  //       x: 0,
  //       y: 0,
  //     ),
  //   );
  //   when(() => systemsCache.systemBySymbol(startSymbol.systemSymbol))
  //       .thenReturn(
  //     System(
  //       symbol: startSymbol.system,
  //       sectorSymbol: startSymbol.sector,
  //       type: SystemType.BLACK_HOLE,
  //       x: 0,
  //       y: 0,
  //     ),
  //   );
  //   when(() => systemsCache.waypointFromSymbol(endSymbol)).thenReturn(
  //     SystemWaypoint(
  //       symbol: endSymbol.waypoint,
  //       type: WaypointType.ASTEROID_FIELD,
  //       x: 0,
  //       y: 0,
  //     ),
  //   );
  //   when(() => systemsCache.systemBySymbol(endSymbol.systemSymbol))
  //        .thenReturn(
  //     System(
  //       symbol: endSymbol.system,
  //       sectorSymbol: endSymbol.sector,
  //       type: SystemType.BLACK_HOLE,
  //       x: 0,
  //       y: 0,
  //     ),
  //   );

  //   when(
  //     () => fleetApi.jumpShip(
  //       shipSymbol.symbol,
  //       jumpShipRequest: JumpShipRequest(systemSymbol: endSymbol.system),
  //     ),
  //   ).thenAnswer(
  //     (_) async => JumpShip200Response(
  //       data: JumpShip200ResponseData(
  //         cooldown: Cooldown(
  //           shipSymbol: shipSymbol.symbol,
  //           totalSeconds: 100,
  //           remainingSeconds: 100,
  //           expiration: reactorExpiry,
  //         ),
  //         nav: shipNav,
  //       ),
  //     ),
  //   );

  //   final singleJumpResult = await runWithLogger(
  //     logger,
  //     () => continueNavigationIfNeeded(
  //       api,
  //       ship,
  //       state,
  //       shipCache,
  //       systemsCache,
  //       centralCommand,
  //       getNow: getNow,
  //     ),
  //   );
  //   // We don't need to return after this jump since the next action may not
  //   // need the reactor.
  //   expect(singleJumpResult.shouldReturn(), false);
  //   expect(
  //     ship.cooldown,
  //     Cooldown(
  //       shipSymbol: shipSymbol.symbol,
  //       remainingSeconds: 100,
  //       expiration: reactorExpiry,
  //       totalSeconds: 100,
  //     ),
  //   );

  //   final jumpTwoSymbol = WaypointSymbol.fromString('G-H-I');
  //   state.routePlan = RoutePlan(
  //     fuelCapacity: 100,
  //     shipSpeed: 100,
  //     actions: [
  //       RouteAction(
  //         startSymbol: startSymbol,
  //         endSymbol: endSymbol,
  //         type: RouteActionType.jump,
  //         duration: 100,
  //       ),
  //       RouteAction(
  //         startSymbol: endSymbol,
  //         endSymbol: jumpTwoSymbol,
  //         type: RouteActionType.jump,
  //         duration: 10,
  //       ),
  //     ],
  //     fuelUsed: 100,
  //   );

  //   // Reset the cooldown.
  //   ship.cooldown = Cooldown(
  //     shipSymbol: shipSymbol.symbol,
  //     totalSeconds: 0,
  //     remainingSeconds: 0,
  //   );
  //   final betweenJumpsResult = await runWithLogger(
  //     logger,
  //     () => continueNavigationIfNeeded(
  //       api,
  //       ship,
  //       state,
  //       shipCache,
  //       systemsCache,
  //       centralCommand,
  //       getNow: getNow,
  //     ),
  //   );
  //   // We don't need to return after this jump since the next action may not
  //   // need the reactor.
  //   expect(betweenJumpsResult.shouldReturn(), true);
  //   expect(ship.cooldown.expiration, reactorExpiry);
  // });

  test('continueNavigationIfNeeded empty plan', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    final shipNav = _MockShipNav();
    final shipNavRoute = _MockShipNavRoute();
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);

    final waypointSymbol = WaypointSymbol.fromString('A-B-C');
    final state = BehaviorState(shipSymbol, Behavior.idle)
      ..routePlan = RoutePlan.empty(
        symbol: waypointSymbol,
        fuelCapacity: 0,
        shipSpeed: 10,
      );

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = _MockLogger();
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);

    final beforeResult = await runWithLogger(
      logger,
      () => continueNavigationIfNeeded(
        api,
        db,
        centralCommand,
        caches,
        ship,
        state,
        getNow: getNow,
      ),
    );
    expect(beforeResult.shouldReturn(), false);
  });
}
