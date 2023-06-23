import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:test/test.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockApi extends Mock implements Api {}

class _MockSystemsApi extends Mock implements SystemsApi {}

void main() {
  test('WaypointCache.waypoint', () async {
    final api = _MockApi();
    final SystemsApi systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final expectedWaypoint = Waypoint(
      symbol: 'S-E-A',
      systemSymbol: 'S-E',
      type: WaypointType.PLANET,
      x: 0,
      y: 0,
    );
    when(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((invocation) async {
      return GetSystemWaypoints200Response(
        data: [expectedWaypoint],
        meta: Meta(total: 1),
      );
    });
    final systemsCache = _MockSystemsCache();
    final waypointCache = WaypointCache(api, systemsCache);
    expect(await waypointCache.waypoint('S-E-A'), expectedWaypoint);
    // Call it twice, it should cache.
    expect(await waypointCache.waypoint('S-E-A'), expectedWaypoint);
    verify(
      () => systemsApi.getSystemWaypoints(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  // Needs work to resurrect this test.
  // Likely overriding the api call to getSystemWaypoints.
  // test('waypointsInJumpRadius', () async {
  //   final aSystem = System(
  //     symbol: 'S-A',
  //     sectorSymbol: 'S',
  //     type: SystemType.RED_STAR,
  //     x: 0,
  //     y: 0,
  //     waypoints: [
  //       SystemWaypoint(
  //         symbol: 'a',
  //         type: WaypointType.PLANET,
  //         x: 0,
  //         y: 0,
  //       ),
  //       SystemWaypoint(
  //         symbol: 'b',
  //         type: WaypointType.PLANET,
  //         x: 0,
  //         y: 0,
  //       ),
  //     ],
  //   );
  //   final bSystem = System(
  //     symbol: 'S-B',
  //     sectorSymbol: 'S',
  //     type: SystemType.RED_STAR,
  //     x: 0,
  //     y: 0,
  //     waypoints: [
  //       SystemWaypoint(
  //         symbol: 'c',
  //         type: WaypointType.PLANET,
  //         x: 0,
  //         y: 0,
  //       ),
  //       SystemWaypoint(
  //         symbol: 'd',
  //         type: WaypointType.PLANET,
  //         x: 0,
  //         y: 0,
  //       ),
  //     ],
  //   );

  //   final systemsCache =
  //       SystemsCache(systems: [aSystem, bSystem],
  //        fs: MemoryFileSystem.test());
  //   final api = _MockApi();
  //   final waypointCache = WaypointCache(api, systemsCache);
  //   final waypoints = await waypointCache
  //       .waypointsInJumpRadius(
  //         startSystem: 'S-A',
  //         maxJumps: 1,
  //       )
  //       .toList();
  //  // This is wrong.
  //   expect(waypoints, [...aSystem.waypoints.map((e) => null),
  //  ...bWaypoints]);
  // });
}
