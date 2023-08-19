import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockApi extends Mock implements Api {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockChartingCache extends Mock implements ChartingCache {}

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
    final symbol = WaypointSymbol.fromString('S-E-A');
    when(() => systemsCache.waypointsInSystem(symbol.systemSymbol)).thenReturn([
      SystemWaypoint(
        symbol: 'S-E-A',
        type: WaypointType.PLANET,
        x: 0,
        y: 0,
      ),
    ]);
    final chartingCache = _MockChartingCache();
    final waypointCache = WaypointCache(api, systemsCache, chartingCache);
    expect(await waypointCache.waypoint(symbol), expectedWaypoint);
    // Call it twice, it should cache.
    expect(await waypointCache.waypoint(symbol), expectedWaypoint);
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
