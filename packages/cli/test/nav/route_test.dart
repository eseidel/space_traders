import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/jump_gate_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/route.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('approximateRoundTripDistanceWithinSystem', () {
    final a =
        SystemWaypoint(symbol: 'a-b-a', type: WaypointType.PLANET, x: 0, y: 0);
    final b =
        SystemWaypoint(symbol: 'a-b-b', type: WaypointType.PLANET, x: 10, y: 0);
    final c =
        SystemWaypoint(symbol: 'a-b-c', type: WaypointType.PLANET, x: 20, y: 0);
    final otherSystem =
        SystemWaypoint(symbol: 'a-c-c', type: WaypointType.PLANET, x: 20, y: 0);
    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(
      [
        System(
          sectorSymbol: a.waypointSymbol.sector,
          symbol: a.waypointSymbol.system,
          type: SystemType.BLUE_STAR,
          x: 0,
          y: 0,
          waypoints: [a, b, c],
        ),
      ],
      fs: fs,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {b.waypointSymbol},
      ),
      20,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {c.waypointSymbol},
      ),
      40,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {b.waypointSymbol, c.waypointSymbol},
      ),
      40,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {},
      ),
      0,
    );
    // Doesn't get confused by having a in the list:
    expect(
      approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {a.waypointSymbol, b.waypointSymbol, c.waypointSymbol},
      ),
      40,
    );
    // Only works with a single system:
    expect(
      () => approximateRoundTripDistanceWithinSystem(
        systemsCache,
        a.waypointSymbol,
        {otherSystem.waypointSymbol},
      ),
      throwsArgumentError,
    );
  });

  test('fuelUsedWithinSystem', () {
    final a =
        SystemWaypoint(symbol: 'a-b-c', type: WaypointType.PLANET, x: 0, y: 0);
    final b =
        SystemWaypoint(symbol: 'a-b-d', type: WaypointType.PLANET, x: 0, y: 0);
    expect(
      fuelUsedWithinSystem(
        a,
        b,
      ),
      0,
    );

    expect(fuelUsedByDistance(10, ShipNavFlightMode.CRUISE), 10);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.DRIFT), 1);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.BURN), 20);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.STEALTH), 10);
  });

  test('flightTimeWithinSystemInSeconds', () {
    final a =
        SystemWaypoint(symbol: 'a-b-c', type: WaypointType.PLANET, x: 0, y: 0);
    final b =
        SystemWaypoint(symbol: 'a-b-d', type: WaypointType.PLANET, x: 0, y: 0);
    expect(
      flightTimeWithinSystemInSeconds(
        a,
        b,
        shipSpeed: 30,
      ),
      15,
    );

    int flightTime(
      double distance,
      int shipSpeed,
      ShipNavFlightMode flightMode,
    ) =>
        flightTimeByDistanceAndSpeed(
          distance: distance,
          shipSpeed: shipSpeed,
          flightMode: flightMode,
        );

    expect(flightTime(1, 30, ShipNavFlightMode.CRUISE), 15);
    expect(flightTime(1, 30, ShipNavFlightMode.DRIFT), 23);

    // Zero is rounded up to one.
    expect(flightTime(0, 30, ShipNavFlightMode.CRUISE), 15);
    expect(flightTime(0, 30, ShipNavFlightMode.DRIFT), 23);

    // Probe zero times.
    expect(flightTime(0, 2, ShipNavFlightMode.CRUISE), 27);

    expect(
      () => flightTime(1, 30, ShipNavFlightMode.BURN),
      throwsUnimplementedError,
    );
    expect(
      () => flightTime(1, 30, ShipNavFlightMode.STEALTH),
      throwsUnimplementedError,
    );

    void check(
      int expected,
      int shipSpeed,
      ShipNavFlightMode flightMode,
      double distance,
    ) {
      final actual = flightTimeByDistanceAndSpeed(
        distance: distance,
        shipSpeed: shipSpeed,
        flightMode: flightMode,
      );
      // TODO(eseidel): Remove this delta. When these were collected we were
      // still comparing current time on the client, now we use server time
      // for both arrival and departure and no longer require slop.
      final delta = (actual - expected).abs();
      expect(delta <= 1, true, reason: '$actual != $expected');
    }

    /// From failure logs:
    check(22, 30, ShipNavFlightMode.CRUISE, 9.43);
    check(22, 3, ShipNavFlightMode.CRUISE, 0);
    check(52, 30, ShipNavFlightMode.CRUISE, 45.71);
    check(89, 3, ShipNavFlightMode.CRUISE, 9.43);
    check(91, 30, ShipNavFlightMode.CRUISE, 92.44);
    check(189, 3, ShipNavFlightMode.CRUISE, 20.81);
    check(267, 30, ShipNavFlightMode.CRUISE, 303.96);
    check(372, 3, ShipNavFlightMode.CRUISE, 43.32);
    check(397, 3, ShipNavFlightMode.CRUISE, 45.71);
    check(406, 3, ShipNavFlightMode.CRUISE, 47.01);
    check(531, 3, ShipNavFlightMode.CRUISE, 62.43);
    check(697, 3, ShipNavFlightMode.CRUISE, 81.88);
    check(972, 3, ShipNavFlightMode.CRUISE, 115.45);
    check(1181, 3, ShipNavFlightMode.CRUISE, 139.81);
    check(3022, 30, ShipNavFlightMode.DRIFT, 360.81);
  });

  test('cooldownTime', () {
    final a = System(
      sectorSymbol: 'S',
      symbol: 'a',
      x: 0,
      y: 0,
      type: SystemType.RED_STAR,
    );
    final b = System(
      sectorSymbol: 'S',
      symbol: 'b',
      x: 2500,
      y: 0,
      type: SystemType.RED_STAR,
    );
    final c = System(
      sectorSymbol: 'S',
      symbol: 'c',
      x: 2501,
      y: 0,
      type: SystemType.RED_STAR,
    );
    expect(cooldownTimeForJumpBetweenSystems(a, b), 250);
    expect(cooldownTimeForJumpBetweenSystems(b, a), 250);

    expect(cooldownTimeForJumpBetweenSystems(b, c), 60);

    expect(cooldownTimeForJumpDistance(2000), 200);
    expect(cooldownTimeForJumpDistance(0), 60);
    // Server seems to round, rather than floor:
    expect(cooldownTimeForJumpDistance(1527), 153);

    expect(() => cooldownTimeForJumpDistance(-20), throwsArgumentError);
  });

  test('planRoute', () {
    const fs = LocalFileSystem();
    // This test originally was written with hard-coded waypoint symbols names
    // but when the SystemWaypoint format changed, it wasn't easy to update, so
    // I made it dynamically compute the waypoint symbols to use from the first
    // waypoint symbol in the file.  Which makes it probably a less good test,
    // but much easier to update in the future if the format changes again.
    final systemsCache = SystemsCache.load(
      fs,
      path: 'test/nav/fixtures/systems-09-24-2023.json',
    )!;
    final jumpGateCache = JumpGateCache([], fs: fs);
    final constructionCache = ConstructionCache([], fs: fs);
    final routePlanner = RoutePlanner.fromCaches(
      systemsCache,
      jumpGateCache,
      constructionCache,
      sellsFuel: (_) => false,
    );
    RoutePlan? planRoute(
      String startString,
      String endString, {
      int fuelCapacity = 1200,
      int shipSpeed = 30,
    }) =>
        routePlanner.planRoute(
          start: WaypointSymbol.fromString(startString),
          end: WaypointSymbol.fromString(endString),
          fuelCapacity: fuelCapacity,
          shipSpeed: shipSpeed,
        );

    void expectRoute(
      String startString,
      String endString,
      int expectedSeconds,
    ) {
      final route = planRoute(startString, endString);
      expect(route, isNotNull);
      expect(route!.duration.inSeconds, expectedSeconds);

      // No need to test caching of the empty route.
      if (route.actions.isEmpty) {
        return;
      }

      // Also verify that our caching works:
      // This actually isn't triggered ever since we're only using local
      // navigation in this test so far.
      final routeSymbols = route.actions.map((w) => w.startSymbol).toList()
        ..add(route.actions.last.endSymbol);
      final route2 = planRoute(startString, endString)!;
      final routeSymbols2 = route2.actions.map((w) => w.startSymbol).toList()
        ..add(route.actions.last.endSymbol);
      // Should be identical when coming from cache.
      expect(routeSymbols2, routeSymbols);
    }

    // Same place
    const waypoint1 = 'X1-V94-96191X'; // first waypoint in systems.json
    expectRoute(waypoint1, waypoint1, 0);

    // Within one system
    final system =
        systemsCache[WaypointSymbol.fromString(waypoint1).systemSymbol];
    final waypointObject2 =
        system.waypoints.firstWhere((w) => w.symbol != waypoint1);
    final waypoint2 = waypointObject2.symbol;
    expectRoute(waypoint1, waypoint2, 23);

    final route = planRoute(waypoint1, waypoint2);
    expect(route!.startSymbol.waypoint, waypoint1);
    expect(route.endSymbol.waypoint, waypoint2);
    // No actions after the last one.
    expect(route.nextActionFrom(WaypointSymbol.fromString(waypoint2)), isNull);
    // Make a sub-plan starting from the same starting point.
    final subPlan = route.subPlanStartingFrom(
      systemsCache,
      WaypointSymbol.fromString(waypoint1),
    );
    expect(subPlan.actions.length, route.actions.length);

    // Make a sub-plan with an unrelated waypoint.
    const waypoint3 = 'X1-TC51-68991C'; // random other waypoint in file.
    expect(
      () => route.subPlanStartingFrom(
        systemsCache,
        // Not in the route.
        WaypointSymbol.fromString(waypoint3),
      ),
      throwsArgumentError,
    );

    // Exactly one jump, jump duration doesn't matter since it doesn't stop
    // navigation.
    // final connectedSystem = systemsCache
    //     .connectedSystems(
    //       WaypointSymbol.fromString(waypoint1).systemSymbol,
    //     )
    //     .first
    //     .systemSymbol;
    // final waypoint4 =
    //     systemsCache.waypointsInSystem(connectedSystem).first.symbol;
    // expectRoute(waypoint1, waypoint4, 118);

    // We don't know how to plan warps yet.
    expect(planRoute(waypoint1, waypoint3), isNull);
  });

  test('planRoute, fuel constraints', () {
    final fs = MemoryFileSystem.test();
    final start = SystemWaypoint(
      symbol: 'A-B-A',
      type: WaypointType.ASTEROID,
      x: 0,
      y: 0,
    );
    final fuelStation = SystemWaypoint(
      symbol: 'A-B-B',
      type: WaypointType.ASTEROID,
      x: 50,
      y: 0,
    );
    final end = SystemWaypoint(
      symbol: 'A-B-C',
      type: WaypointType.ASTEROID,
      x: 100,
      y: 0,
    );

    final systemsCache = SystemsCache(
      [
        System(
          symbol: 'A-B',
          sectorSymbol: 'A',
          type: SystemType.BLUE_STAR,
          x: 0,
          y: 0,
          waypoints: [start, fuelStation, end],
        ),
      ],
      fs: fs,
    );

    final jumpGateCache = JumpGateCache([], fs: fs);
    final constructionCache = ConstructionCache([], fs: fs);
    final routePlanner = RoutePlanner.fromCaches(
      systemsCache,
      jumpGateCache,
      constructionCache,
      // Allow refueling at waypoints or this test will fail.
      sellsFuel: (_) => true,
    );
    RoutePlan? planRoute(
      SystemWaypoint start,
      SystemWaypoint end, {
      required int fuelCapacity,
      int shipSpeed = 30,
    }) =>
        routePlanner.planRoute(
          start: start.waypointSymbol,
          end: end.waypointSymbol,
          fuelCapacity: fuelCapacity,
          shipSpeed: shipSpeed,
        );
    // If tank is large enough, we just go direct.
    final big = planRoute(start, end, fuelCapacity: 101)!.actions;
    expect(big.length, 1);
    expect(big[0].startSymbol, start.waypointSymbol);
    expect(big[0].endSymbol, end.waypointSymbol);
    expect(big[0].type, RouteActionType.navCruise);

    // If it's large enough to make it to the fuel station, we go there
    // refuel and continue to our destination.
    // TODO(eseidel): We should never plan a route that uses exactly all fuel.
    // 100 should fail here, right now we use <=.
    final medium = planRoute(start, end, fuelCapacity: 99)!.actions;
    expect(medium[0].type, RouteActionType.navCruise);
    expect(medium[0].startSymbol, start.waypointSymbol);
    expect(medium[0].endSymbol, fuelStation.waypointSymbol);
    expect(medium.length, 3);
    expect(medium[1].type, RouteActionType.refuel);
    expect(medium[1].startSymbol, fuelStation.waypointSymbol);
    expect(medium[1].endSymbol, fuelStation.waypointSymbol);
    expect(medium[2].type, RouteActionType.navCruise);
    expect(medium[2].startSymbol, fuelStation.waypointSymbol);
    expect(medium[2].endSymbol, end.waypointSymbol);

    // If it's not large enough to make it to the fuel station, we just
    // drift straight there.
    final little = planRoute(start, end, fuelCapacity: 20)!.actions;
    expect(little.length, 1);
    expect(little[0].startSymbol, start.waypointSymbol);
    expect(little[0].endSymbol, end.waypointSymbol);
    expect(little[0].type, RouteActionType.navDrift);

    // Ships that don't use fuel always just cruise.
    final noFuel = planRoute(start, end, fuelCapacity: 0)!.actions;
    expect(noFuel.length, 1);
    expect(noFuel[0].startSymbol, start.waypointSymbol);
    expect(noFuel[0].endSymbol, end.waypointSymbol);
    expect(noFuel[0].type, RouteActionType.navCruise);
  });

  test('RoutePlan', () {
    final one = RouteAction(
      type: RouteActionType.navCruise,
      startSymbol: WaypointSymbol.fromString('A-B-A'),
      endSymbol: WaypointSymbol.fromString('A-B-B'),
      seconds: 10,
      fuelUsed: 10,
    );
    final two = RouteAction(
      type: RouteActionType.refuel,
      startSymbol: WaypointSymbol.fromString('A-B-B'),
      endSymbol: WaypointSymbol.fromString('A-B-B'),
      seconds: 10,
      fuelUsed: 0,
    );
    final three = RouteAction(
      type: RouteActionType.navCruise,
      startSymbol: WaypointSymbol.fromString('A-B-B'),
      endSymbol: WaypointSymbol.fromString('A-B-C'),
      seconds: 10,
      fuelUsed: 10,
    );

    final plan = RoutePlan(
      actions: [one, two, three],
      fuelCapacity: 100,
      shipSpeed: 30,
    );
    expect(plan.nextActionFrom(one.endSymbol), two);
    expect(plan.nextActionFrom(three.endSymbol), isNull);
    expect(plan.actionAfter(one), two);
    expect(plan.actionAfter(two), three);
    expect(plan.actionAfter(three), isNull);

    expect(plan.requestCount, 5);
    expect(one.usesReactor, false);
    expect(one.duration, const Duration(seconds: 10));
  });

  test('describeRoutePlan', () {
    final start = WaypointSymbol.fromString('A-B-A');
    final plan =
        RoutePlan.empty(symbol: start, fuelCapacity: 10, shipSpeed: 30);
    expect(
        describeRoutePlan(plan),
        'B-A to B-A speed: 30 max-fuel: 10\n'
        'emptyRoute      B-A  B-A  0:00:00.000000s\n'
        'in 0ms uses 0 fuel\n');
  });
}
