import 'dart:convert';

import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('approximateRoundTripDistanceWithinSystem', () {
    final aSymbol = WaypointSymbol.fromString('a-b-a');
    final a = SystemWaypoint.test(aSymbol);
    final bSymbol = WaypointSymbol.fromString('a-b-b');
    final b = SystemWaypoint.test(
      bSymbol,
      position: WaypointPosition(10, 0, bSymbol.system),
    );
    final cSymbol = WaypointSymbol.fromString('a-b-c');
    final c = SystemWaypoint.test(
      cSymbol,
      position: WaypointPosition(20, 0, cSymbol.system),
    );
    final otherSymbol = WaypointSymbol.fromString('a-c-c');
    final otherSystem = SystemWaypoint.test(
      otherSymbol,
      position: WaypointPosition(20, 0, otherSymbol.system),
    );
    final system = System.test(a.system, waypoints: [a, b, c]);
    final otherSystemSystem = System.test(
      otherSystem.system,
      waypoints: [otherSystem],
    );
    final systemsCache = SystemsSnapshot([system, otherSystemSystem]);
    expect(
      approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {
        b.symbol,
      }),
      20,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {
        c.symbol,
      }),
      40,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {
        b.symbol,
        c.symbol,
      }),
      40,
    );
    expect(
      approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {}),
      0,
    );
    // Doesn't get confused by having a in the list:
    expect(
      approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {
        a.symbol,
        b.symbol,
        c.symbol,
      }),
      40,
    );
    // Only works with a single system:
    expect(
      () => approximateRoundTripDistanceWithinSystem(systemsCache, a.symbol, {
        otherSystem.symbol,
      }),
      throwsArgumentError,
    );
  });

  test('fuelUsedWithinSystem', () {
    final a = SystemWaypoint.test(WaypointSymbol.fromString('a-b-c'));
    final b = SystemWaypoint.test(WaypointSymbol.fromString('a-b-d'));
    expect(fuelUsedWithinSystem(a, b), 0);

    expect(fuelUsedByDistance(10, ShipNavFlightMode.CRUISE), 10);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.DRIFT), 1);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.BURN), 20);
    expect(fuelUsedByDistance(10, ShipNavFlightMode.STEALTH), 10);
  });

  test('flightTimeWithinSystemInSeconds', () {
    final a = SystemWaypoint.test(WaypointSymbol.fromString('a-b-c'));
    final b = SystemWaypoint.test(WaypointSymbol.fromString('a-b-d'));
    expect(flightTimeWithinSystemInSeconds(a, b, shipSpeed: 30), 15);

    int flightTime(
      double distance,
      int shipSpeed,
      ShipNavFlightMode flightMode,
    ) => flightTimeByDistanceAndSpeed(
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
    final a = SystemRecord.test(SystemSymbol.fromString('A-A'));
    final b = SystemRecord.test(
      SystemSymbol.fromString('A-B'),
      position: const SystemPosition(2500, 0),
    );
    final c = SystemRecord.test(
      SystemSymbol.fromString('A-C'),
      position: const SystemPosition(2501, 0),
    );
    expect(cooldownTimeForJumpBetweenSystems(a, b), 765);
    expect(cooldownTimeForJumpBetweenSystems(b, a), 765);

    expect(cooldownTimeForJumpBetweenSystems(b, c), 15);

    expect(cooldownTimeForJumpDistance(2000), 615);
    expect(cooldownTimeForJumpDistance(0), 15);
    // Server seems to round, rather than floor:
    expect(cooldownTimeForJumpDistance(1527), 473);

    expect(() => cooldownTimeForJumpDistance(-20), throwsArgumentError);
  });

  SystemsSnapshot loadFromFile(String path) {
    const fs = LocalFileSystem();
    final file = fs.file(path);
    final json = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    final systems = json
        .map((e) => System.fromJson(e as Map<String, dynamic>))
        .toList();
    return SystemsSnapshot(systems);
  }

  test('planRoute', () {
    // This test originally was written with hard-coded waypoint symbols names
    // but when the SystemWaypoint format changed, it wasn't easy to update, so
    // I made it dynamically compute the waypoint symbols to use from the first
    // waypoint symbol in the file.  Which makes it probably a less good test,
    // but much easier to update in the future if the format changes again.
    final systemsCache = loadFromFile(
      'test/nav/fixtures/systems-09-24-2023.json',
    );
    final waypoint1 = WaypointSymbol.fromString(
      'X1-V94-96191X',
    ); // first waypoint in systems.json
    final waypoint3 = WaypointSymbol.fromString(
      'X1-TC51-68991C',
    ); // random other waypoint in file.
    final waypoint4 = WaypointSymbol.fromString(
      'X1-CH89-70689B',
    ); // another random other waypoint in file.

    final systemConnectivity = SystemConnectivity.test({
      waypoint1: {waypoint4},
    });
    final routePlanner = RoutePlanner.fromSystemsSnapshot(
      systemsCache,
      systemConnectivity,
      sellsFuel: (_) => false,
    );
    RoutePlan? planRoute(
      WaypointSymbol start,
      WaypointSymbol end, {
      int fuelCapacity = 1200,
      int shipSpeed = 30,
    }) => routePlanner.planRoute(
      ShipSpec(
        cargoCapacity: 0,
        fuelCapacity: fuelCapacity,
        speed: shipSpeed,
        canWarp: false,
      ),
      start: start,
      end: end,
    );

    void expectRoute(
      WaypointSymbol start,
      WaypointSymbol end,
      int expectedSeconds,
    ) {
      final route = planRoute(start, end);
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
      final route2 = planRoute(start, end)!;
      final routeSymbols2 = route2.actions.map((w) => w.startSymbol).toList()
        ..add(route.actions.last.endSymbol);
      // Should be identical when coming from cache.
      expect(routeSymbols2, routeSymbols);
    }

    // Same place
    expectRoute(waypoint1, waypoint1, 0);

    // Within one system
    final system = systemsCache.systemBySymbol(waypoint1.system);
    final waypoint2 = system.waypoints
        .firstWhere((w) => w.symbol != waypoint1)
        .symbol;
    expectRoute(waypoint1, waypoint2, 23);

    final route = planRoute(waypoint1, waypoint2);
    expect(route!.startSymbol, waypoint1);
    expect(route.endSymbol, waypoint2);
    // No actions after the last one.
    expect(route.nextActionFrom(waypoint2), isNull);
    // Make a sub-plan starting from the same starting point.
    final subPlan = route.subPlanStartingFrom(waypoint1);
    expect(subPlan.actions.length, route.actions.length);

    // Make a sub-plan with an unrelated waypoint.
    expect(() => route.subPlanStartingFrom(waypoint3), throwsArgumentError);

    // Exactly one jump, jump duration doesn't matter since it doesn't stop
    // navigation.
    expectRoute(waypoint1, waypoint4, 80);

    // We don't know how to plan warps yet.
    expect(planRoute(waypoint1, waypoint3), isNull);
  });

  test('planRoute, fuel constraints', () {
    final systemSymbol = SystemSymbol.fromString('A-B');
    final start = SystemWaypoint.test(WaypointSymbol.fromString('A-B-A'));
    final fuelStation = SystemWaypoint.test(
      WaypointSymbol.fromString('A-B-B'),
      position: WaypointPosition(50, 0, systemSymbol),
    );
    final end = SystemWaypoint.test(
      WaypointSymbol.fromString('A-B-C'),
      position: WaypointPosition(100, 0, systemSymbol),
    );

    final system = System.test(
      systemSymbol,
      waypoints: [start, fuelStation, end],
    );
    final systemsCache = SystemsSnapshot([system]);

    final systemConnectivity = SystemConnectivity.test(const {});
    final routePlanner = RoutePlanner.fromSystemsSnapshot(
      systemsCache,
      systemConnectivity,
      // Allow refueling at waypoints or this test will fail.
      sellsFuel: (_) => true,
    );
    RoutePlan? planRoute(
      SystemWaypoint start,
      SystemWaypoint end, {
      required int fuelCapacity,
      int shipSpeed = 30,
    }) => routePlanner.planRoute(
      ShipSpec(
        cargoCapacity: 0,
        fuelCapacity: fuelCapacity,
        speed: shipSpeed,
        canWarp: false,
      ),
      start: start.symbol,
      end: end.symbol,
    );
    // If tank is large enough, we just go direct.
    final big = planRoute(start, end, fuelCapacity: 101)!.actions;
    expect(big.length, 1);
    expect(big[0].startSymbol, start.symbol);
    expect(big[0].endSymbol, end.symbol);
    expect(big[0].type, RouteActionType.navCruise);

    // If it's large enough to make it to the fuel station, we go there
    // refuel and continue to our destination.
    // TODO(eseidel): We should never plan a route that uses exactly all fuel.
    // 100 should fail here, right now we use <=.
    final medium = planRoute(start, end, fuelCapacity: 99)!.actions;
    expect(medium[0].type, RouteActionType.navCruise);
    expect(medium[0].startSymbol, start.symbol);
    expect(medium[0].endSymbol, fuelStation.symbol);
    expect(medium.length, 3);
    expect(medium[1].type, RouteActionType.refuel);
    expect(medium[1].startSymbol, fuelStation.symbol);
    expect(medium[1].endSymbol, fuelStation.symbol);
    expect(medium[2].type, RouteActionType.navCruise);
    expect(medium[2].startSymbol, fuelStation.symbol);
    expect(medium[2].endSymbol, end.symbol);

    // If it's not large enough to make it to the fuel station, we just
    // drift straight there.
    final little = planRoute(start, end, fuelCapacity: 20)!.actions;
    expect(little.length, 1);
    expect(little[0].startSymbol, start.symbol);
    expect(little[0].endSymbol, end.symbol);
    expect(little[0].type, RouteActionType.navDrift);

    // Ships that don't use fuel always just cruise.
    final noFuel = planRoute(start, end, fuelCapacity: 0)!.actions;
    expect(noFuel.length, 1);
    expect(noFuel[0].startSymbol, start.symbol);
    expect(noFuel[0].endSymbol, end.symbol);
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
    final two = RouteAction.refuel(WaypointSymbol.fromString('A-B-B'));
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
    final plan = RoutePlan.empty(
      symbol: start,
      fuelCapacity: 10,
      shipSpeed: 30,
    );
    expect(
      describeRoutePlan(plan),
      'B-A to B-A speed: 30 max-fuel: 10\n'
      'emptyRoute      B-A  B-A 0ms 0 fuel\n'
      'in 0ms uses 0 fuel\n',
    );
  });
}
