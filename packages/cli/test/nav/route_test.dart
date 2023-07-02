import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/route.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';

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
  });

  test('planRouteFor', () {
    const fs = LocalFileSystem();
    final systemsCache = SystemsCache.loadFromCache(
      fs,
      path: 'test/nav/fixtures/systems-06-24-2023.json',
    )!;
    void expectRoute(String start, String end, int expectedSeconds) {
      final startWaypoint = systemsCache.waypointFromSymbol(start);
      final endWaypoint = systemsCache.waypointFromSymbol(end);
      final route = planRoute(
        systemsCache,
        start: startWaypoint,
        end: endWaypoint,
        fuelCapacity: 1200,
        shipSpeed: 30,
      );
      expect(route, isNotNull);
      expect(route!.duration, expectedSeconds);
    }

    // Within one system
    expectRoute('X1-YU85-99640B', 'X1-YU85-07121B', 25);
    // Exactly one jump, jump duration doesn't matter since it doesn't stop
    // navigation.
    expectRoute('X1-RG48-59920X', 'X1-TV72-74710F', 90);
  });
}
