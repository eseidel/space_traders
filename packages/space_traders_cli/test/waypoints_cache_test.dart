import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';

class MockSystemsCache extends Mock implements SystemsCache {}

class MockApi extends Mock implements Api {}

void main() {
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
  //   final api = MockApi();
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
