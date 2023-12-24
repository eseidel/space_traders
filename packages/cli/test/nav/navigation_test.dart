import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/market_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockAgent extends Mock implements Agent {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockShipReactor extends Mock implements ShipReactor {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipRegistration extends Mock implements ShipRegistration {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipCrew extends Mock implements ShipCrew {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

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

  test('continueNavigationIfNeeded sets cooldown after jump', () async {
    final api = _MockApi();
    final caches = mockCaches();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipNav = _MockShipNav();
    final agent = _MockAgent();
    when(() => agent.credits).thenReturn(10000000);
    when(() => caches.agent.agent).thenReturn(agent);
    const shipSymbol = ShipSymbol('S', 1);
    // We use a real Ship to allow setting/reading from cooldown.
    final ship = Ship(
      symbol: shipSymbol.symbol,
      cooldown: Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
      ),
      nav: shipNav,
      reactor: _MockShipReactor(),
      engine: _MockShipEngine(),
      registration: _MockShipRegistration(),
      frame: _MockShipFrame(),
      crew: _MockShipCrew(),
      cargo: _MockShipCargo(),
      fuel: _MockShipFuel(),
    );

    final centralCommand = _MockCentralCommand();
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);

    /// The behavior doesn't matter, just needs to have a null destination.
    final state = BehaviorState(shipSymbol, Behavior.idle);

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = _MockLogger();

    final startSymbol = WaypointSymbol.fromString('A-B-C');
    final endSymbol = WaypointSymbol.fromString('D-E-F');

    when(() => shipNav.waypointSymbol).thenReturn(startSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(startSymbol.system);

    state.routePlan = RoutePlan(
      fuelCapacity: 100,
      shipSpeed: 100,
      actions: [
        RouteAction(
          startSymbol: startSymbol,
          endSymbol: endSymbol,
          type: RouteActionType.jump,
          seconds: 100,
          fuelUsed: 0,
        ),
      ],
    );
    final reactorExpiry = now.add(const Duration(seconds: 100));

    when(() => caches.systems.waypoint(startSymbol)).thenReturn(
      SystemWaypoint(
        symbol: startSymbol.waypoint,
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );
    when(() => caches.systems[startSymbol.systemSymbol]).thenReturn(
      System(
        symbol: startSymbol.system,
        sectorSymbol: startSymbol.sector,
        type: SystemType.BLACK_HOLE,
        x: 0,
        y: 0,
      ),
    );
    when(() => caches.systems.waypoint(endSymbol)).thenReturn(
      SystemWaypoint(
        symbol: endSymbol.waypoint,
        type: WaypointType.JUMP_GATE,
        x: 0,
        y: 0,
      ),
    );
    when(() => caches.systems[endSymbol.systemSymbol]).thenReturn(
      System(
        symbol: endSymbol.system,
        sectorSymbol: endSymbol.sector,
        type: SystemType.BLACK_HOLE,
        x: 0,
        y: 0,
      ),
    );

    when(
      () => fleetApi.jumpShip(
        shipSymbol.symbol,
        jumpShipRequest: JumpShipRequest(waypointSymbol: endSymbol.waypoint),
      ),
    ).thenAnswer(
      (_) async => JumpShip200Response(
        data: JumpShip200ResponseData(
          cooldown: Cooldown(
            shipSymbol: shipSymbol.symbol,
            totalSeconds: 100,
            remainingSeconds: 100,
            expiration: reactorExpiry,
          ),
          nav: shipNav,
          transaction: MarketTransaction(
            waypointSymbol: startSymbol.waypoint,
            shipSymbol: shipSymbol.symbol,
            tradeSymbol: TradeSymbol.ANTIMATTER.value,
            type: MarketTransactionTypeEnum.PURCHASE,
            units: 1,
            pricePerUnit: 10000,
            totalPrice: 10000,
            timestamp: now,
          ),
          agent: agent,
        ),
      ),
    );

    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) async {});

    final singleJumpResult = await runWithLogger(
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
    // We don't need to return after this jump since the next action may not
    // need the reactor.
    expect(singleJumpResult.shouldReturn(), false);
    expect(
      ship.cooldown,
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        remainingSeconds: 100,
        expiration: reactorExpiry,
        totalSeconds: 100,
      ),
    );

    final jumpTwoSymbol = WaypointSymbol.fromString('G-H-I');
    state.routePlan = RoutePlan(
      fuelCapacity: 100,
      shipSpeed: 100,
      actions: [
        RouteAction(
          startSymbol: startSymbol,
          endSymbol: endSymbol,
          type: RouteActionType.jump,
          seconds: 100,
          fuelUsed: 0,
        ),
        RouteAction(
          startSymbol: endSymbol,
          endSymbol: jumpTwoSymbol,
          type: RouteActionType.jump,
          seconds: 10,
          fuelUsed: 0,
        ),
      ],
    );

    // Reset the cooldown.
    ship.cooldown = Cooldown(
      shipSymbol: shipSymbol.symbol,
      totalSeconds: 0,
      remainingSeconds: 0,
    );
    final betweenJumpsResult = await runWithLogger(
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
    // We don't need to return after this jump since the next action may not
    // need the reactor.
    expect(betweenJumpsResult.shouldReturn(), true);
    expect(ship.cooldown.expiration, reactorExpiry);
  });

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

    final result = await runWithLogger(
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
    expect(state.routePlan, isNull);
    expect(result.shouldReturn(), false);
  });

  test('continueNavigationIfNeeded already at end', () async {
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

    final start = WaypointSymbol.fromString('A-B-A');
    final end = WaypointSymbol.fromString('A-B-B');
    final state = BehaviorState(shipSymbol, Behavior.idle)
      ..routePlan = RoutePlan(
        fuelCapacity: 100,
        shipSpeed: 10,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
      );

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = _MockLogger();
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNav.waypointSymbol).thenReturn(end.waypoint);

    final result = await runWithLogger(
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
    expect(state.routePlan, isNull);
    expect(result.shouldReturn(), false);
  });

  test('continueNavigationIfNeeded off course', () async {
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

    final start = WaypointSymbol.fromString('A-B-A');
    final end = WaypointSymbol.fromString('A-B-B');
    final other = WaypointSymbol.fromString('A-B-C');
    final state = BehaviorState(shipSymbol, Behavior.idle)
      ..routePlan = RoutePlan(
        fuelCapacity: 100,
        shipSpeed: 10,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
      );

    final now = DateTime(2021);
    DateTime getNow() => now;
    final logger = _MockLogger();
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNav.waypointSymbol).thenReturn(other.waypoint);

    expect(
      () async => await runWithLogger(
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
      ),
      throwsA(isA<JobException>()),
    );
    // Maybe it should clear the route?
    expect(state.routePlan, isNotNull);
  });

  test('defaultSellsFuel', () {
    final listings = _MockMarketListingCache();
    final sellsFuel = defaultSellsFuel(listings);
    final waypointSymbol = WaypointSymbol.fromString('A-B-C');
    when(() => listings[waypointSymbol])
        .thenReturn(MarketListing(waypointSymbol: waypointSymbol));
    expect(sellsFuel(waypointSymbol), false);

    when(() => listings[waypointSymbol]).thenReturn(
      MarketListing(
        waypointSymbol: waypointSymbol,
        exchange: const {TradeSymbol.FUEL},
      ),
    );
    expect(sellsFuel(waypointSymbol), true);
  });

  test('Ship.timeToArrival', () {
    final startSymbol = WaypointSymbol.fromString('A-A-A');
    final jumpASymbol = WaypointSymbol.fromString('A-A-B');
    final jumpBSymbol = WaypointSymbol.fromString('A-B-C');
    final endSymbol = WaypointSymbol.fromString('A-B-D');

    final routePlan = RoutePlan(
      fuelCapacity: 100,
      shipSpeed: 100,
      actions: [
        RouteAction(
          startSymbol: startSymbol,
          endSymbol: jumpASymbol,
          type: RouteActionType.navCruise,
          seconds: 1,
          fuelUsed: 0,
        ),
        RouteAction(
          startSymbol: jumpASymbol,
          endSymbol: jumpBSymbol,
          type: RouteActionType.jump,
          seconds: 22,
          fuelUsed: 0,
        ),
        RouteAction(
          startSymbol: jumpBSymbol,
          endSymbol: endSymbol,
          type: RouteActionType.navCruise,
          seconds: 3,
          fuelUsed: 0,
        ),
      ],
    );

    // We don't need a real object to test extension methods.
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.waypointSymbol).thenReturn(startSymbol.waypoint);
    expect(ship.timeToArrival(routePlan), const Duration(seconds: 26));
  });
}
