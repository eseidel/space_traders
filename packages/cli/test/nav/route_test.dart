import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/route.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
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

    expect(flightTimeByDistanceAndSpeed(1, 30, ShipNavFlightMode.CRUISE), 15);
    expect(flightTimeByDistanceAndSpeed(1, 30, ShipNavFlightMode.DRIFT), 20);
    expect(flightTimeByDistanceAndSpeed(1, 30, ShipNavFlightMode.BURN), 15);

    // Zero is rounded up to one.
    expect(flightTimeByDistanceAndSpeed(0, 30, ShipNavFlightMode.CRUISE), 15);
    expect(flightTimeByDistanceAndSpeed(0, 30, ShipNavFlightMode.DRIFT), 20);
    expect(flightTimeByDistanceAndSpeed(0, 30, ShipNavFlightMode.BURN), 15);

    // Probe zero times.
    expect(flightTimeByDistanceAndSpeed(0, 2, ShipNavFlightMode.CRUISE), 22);
    expect(flightTimeByDistanceAndSpeed(0, 2, ShipNavFlightMode.BURN), 18);

    expect(
      () => flightTimeByDistanceAndSpeed(1, 30, ShipNavFlightMode.STEALTH),
      throwsUnimplementedError,
    );
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
      x: kJumpGateRange,
      y: 0,
      type: SystemType.RED_STAR,
    );
    final c = System(
      sectorSymbol: 'S',
      symbol: 'c',
      x: kJumpGateRange + 1,
      y: 0,
      type: SystemType.RED_STAR,
    );
    // These constants vary with kJumpGateRange.
    expect(cooldownTimeForJumpBetweenSystems(a, b), 250);
    expect(cooldownTimeForJumpBetweenSystems(b, a), 250);

    expect(() => cooldownTimeForJumpBetweenSystems(a, c), throwsArgumentError);
    expect(() => cooldownTimeForJumpBetweenSystems(a, a), throwsArgumentError);
    expect(cooldownTimeForJumpBetweenSystems(b, c), 60);

    expect(cooldownTimeForJumpDistance(2000), 200);
    expect(cooldownTimeForJumpDistance(0), 60);
    // Server seems to round, rather than floor:
    expect(cooldownTimeForJumpDistance(1527), 153);

    expect(
      () => cooldownTimeForJumpDistance(kJumpGateRange + 1),
      throwsArgumentError,
    );
    expect(() => cooldownTimeForJumpDistance(-20), throwsArgumentError);
    expect(
      () => cooldownTimeForJumpDistance(-kJumpGateRange - 1),
      throwsArgumentError,
    );
  });

  test('planRoute', () {
    const fs = LocalFileSystem();
    // This test originally was written with hard-coded waypoint symbols names
    // but when the SystemWaypoint format changed, it wasn't easy to update, so
    // I made it dynamically compute the waypoint symbols to use from the first
    // waypoint symbol in the file.  Which makes it probably a less good test,
    // but much easier to update in the future if the format changes again.
    final systemsCache = SystemsCache.loadCached(
      fs,
      path: 'test/nav/fixtures/systems-09-24-2023.json',
    )!;
    final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);
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
    final system = systemsCache
        .systemBySymbol(WaypointSymbol.fromString(waypoint1).systemSymbol);
    final waypointObject2 =
        system.waypoints.firstWhere((w) => w.symbol != waypoint1);
    final waypoint2 = waypointObject2.symbol;
    expectRoute(waypoint1, waypoint2, 20);

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
    final connectedSystem = systemsCache
        .connectedSystems(
          WaypointSymbol.fromString(waypoint1).systemSymbol,
        )
        .first
        .systemSymbol;
    final waypoint4 =
        systemsCache.waypointsInSystem(connectedSystem).first.symbol;
    expectRoute(waypoint1, waypoint4, 118);

    // We don't know how to plan warps yet.
    expect(planRoute(waypoint1, waypoint3), isNull);
  });
}
