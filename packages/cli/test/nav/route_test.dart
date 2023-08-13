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
      x: 2000,
      y: 0,
      type: SystemType.RED_STAR,
    );
    final c = System(
      sectorSymbol: 'S',
      symbol: 'c',
      x: 2001,
      y: 0,
      type: SystemType.RED_STAR,
    );
    expect(cooldownTimeForJumpBetweenSystems(a, b), 200);
    expect(cooldownTimeForJumpBetweenSystems(b, a), 200);
    expect(() => cooldownTimeForJumpBetweenSystems(a, c), throwsArgumentError);
    expect(() => cooldownTimeForJumpBetweenSystems(a, a), throwsArgumentError);
    expect(cooldownTimeForJumpBetweenSystems(b, c), 60);

    expect(cooldownTimeForJumpDistance(2000), 200);
    expect(cooldownTimeForJumpDistance(0), 60);
    // Server seems to round, rather than floor:
    expect(cooldownTimeForJumpDistance(1527), 153);
    expect(() => cooldownTimeForJumpDistance(2001), throwsArgumentError);
    expect(() => cooldownTimeForJumpDistance(-20), throwsArgumentError);
    expect(() => cooldownTimeForJumpDistance(-2001), throwsArgumentError);
  });

  test('planRoute', () {
    const fs = LocalFileSystem();
    final systemsCache = SystemsCache.loadCached(
      fs,
      path: 'test/nav/fixtures/systems-06-24-2023.json',
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
    expectRoute('X1-YU85-99640B', 'X1-YU85-99640B', 0);

    // Within one system
    expectRoute('X1-YU85-99640B', 'X1-YU85-07121B', 30);

    final route = planRoute('X1-YU85-99640B', 'X1-YU85-07121B');
    expect(route!.startSymbol, WaypointSymbol.fromString('X1-YU85-99640B'));
    expect(route.endSymbol, WaypointSymbol.fromString('X1-YU85-07121B'));
    expect(
      () => route.nextActionFrom(
        // No actions after the last one.
        WaypointSymbol.fromString('X1-YU85-07121B'),
      ),
      throwsArgumentError,
    );
    // Make a sub-plan starting from the same starting point.
    final subPlan = route.subPlanStartingFrom(
      systemsCache,
      // Not in the route.
      WaypointSymbol.fromString('X1-YU85-99640B'),
    );
    expect(subPlan.actions.length, route.actions.length);
    expect(
      () => route.subPlanStartingFrom(
        systemsCache,
        // Not in the route.
        WaypointSymbol.fromString('X1-RG48-59920X'),
      ),
      throwsArgumentError,
    );

    // Exactly one jump, jump duration doesn't matter since it doesn't stop
    // navigation.
    expectRoute('X1-RG48-59920X', 'X1-TV72-74710F', 129);

    // We don't know how to plan warps yet.
    expect(planRoute('X1-YU85-07121B', 'X1-RG48-59920X'), isNull);
  });
}
