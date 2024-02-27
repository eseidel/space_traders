import 'package:cli/api.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/market_listing_snapshot.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/navigation.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

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

class _MockMarketListingSnapshot extends Mock
    implements MarketListingSnapshot {}

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
    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);
    when(() => caches.agent.updateAgent(agent)).thenAnswer((_) async {});
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
    when(() => shipNav.systemSymbol).thenReturn(startSymbol.systemString);

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
      SystemWaypoint.test(
        startSymbol,
        type: WaypointType.ASTEROID_FIELD,
      ),
    );
    when(() => caches.systems[startSymbol.system]).thenReturn(
      System.test(startSymbol.system),
    );
    when(() => caches.systems.waypoint(endSymbol)).thenReturn(
      SystemWaypoint.test(
        endSymbol,
        type: WaypointType.JUMP_GATE,
      ),
    );
    when(() => caches.systems[endSymbol.system]).thenReturn(
      System.test(endSymbol.system),
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
          agent: agent.toOpenApi(),
        ),
      ),
    );

    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) async {});
    when(() => db.upsertShip(ship)).thenAnswer((_) => Future.value());

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
    final listings = _MockMarketListingSnapshot();
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
    final jumpCSymbol = WaypointSymbol.fromString('A-C-D');
    final endSymbol = WaypointSymbol.fromString('A-C-E');

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
          endSymbol: jumpCSymbol,
          type: RouteActionType.jump,
          seconds: 33,
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
    const shipSymbol = ShipSymbol('A', 1);
    final shipNav = _MockShipNav();
    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.nav).thenReturn(shipNav);
    final shipNavRoute = _MockShipNavRoute();
    when(() => shipNav.route).thenReturn(shipNavRoute);

    Duration timeToArrival({
      required ShipNavStatus status,
      required WaypointSymbol location,
      Duration? cooldown,
      Duration? arrival,
    }) {
      when(() => shipNav.status).thenReturn(status);
      when(() => shipNav.waypointSymbol).thenReturn(location.waypoint);
      when(() => shipNavRoute.arrival).thenReturn(
        arrival == null ? now : now.add(const Duration(minutes: 1)),
      );
      final cooldownDuration = cooldown ?? Duration.zero;
      when(() => ship.cooldown).thenReturn(
        Cooldown(
          shipSymbol: shipSymbol.symbol,
          totalSeconds: cooldownDuration.inSeconds,
          remainingSeconds: cooldownDuration.inSeconds,
          expiration: now.add(cooldownDuration),
        ),
      );
      return ship.timeToArrival(routePlan, getNow: getNow);
    }

    // Orbiting the first waypoint.
    expect(
      timeToArrival(
        status: ShipNavStatus.IN_ORBIT,
        location: startSymbol,
      ),
      const Duration(seconds: 59),
    );

    // In transit to the first waypoint.
    expect(
      timeToArrival(
        status: ShipNavStatus.IN_TRANSIT,
        arrival: const Duration(minutes: 1),
        location: startSymbol,
      ),
      const Duration(seconds: 119),
    );

    /// In transit to the second waypoint.
    expect(
      timeToArrival(
        status: ShipNavStatus.IN_TRANSIT,
        location: jumpASymbol,
        arrival: const Duration(minutes: 1),
      ),
      const Duration(seconds: 118),
    );

    /// Waiting at the first jump
    expect(
      timeToArrival(
        status: ShipNavStatus.IN_ORBIT,
        location: jumpASymbol,
        cooldown: const Duration(minutes: 2),
      ),
      // 120s (cooldown) + 58 (remaining travel) = 178
      const Duration(seconds: 178),
    );

    /// Waiting at the second jump
    expect(
      timeToArrival(
        status: ShipNavStatus.IN_ORBIT,
        location: jumpBSymbol,
        cooldown: const Duration(minutes: 2),
      ),
      const Duration(seconds: 156),
    );
  });
}
