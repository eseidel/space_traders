import 'package:mocktail/mocktail.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/waypoint_cache.dart';
import 'package:test/test.dart';

class MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('waypointsInJumpRadius', () async {
    final WaypointCache waypointCache = MockWaypointCache();
    final aWaypoints = [
      Waypoint(
        symbol: 'a',
        type: WaypointType.PLANET,
        systemSymbol: 'A',
        x: 0,
        y: 0,
      ),
      Waypoint(
        symbol: 'b',
        type: WaypointType.PLANET,
        systemSymbol: 'A',
        x: 0,
        y: 0,
      ),
    ];
    final bWaypoints = [
      Waypoint(
        symbol: 'c',
        type: WaypointType.PLANET,
        systemSymbol: 'B',
        x: 0,
        y: 0,
      ),
      Waypoint(
        symbol: 'd',
        type: WaypointType.PLANET,
        systemSymbol: 'B',
        x: 0,
        y: 0,
      ),
    ];
    when(() => waypointCache.waypointsInSystem('A'))
        .thenAnswer((invocation) => Future.value(aWaypoints));
    when(() => waypointCache.waypointsInSystem('B'))
        .thenAnswer((invocation) => Future.value(bWaypoints));
    when(() => waypointCache.connectedSystems('A')).thenAnswer(
      (invocation) => Stream.value(
        ConnectedSystem(
          symbol: 'B',
          sectorSymbol: 'B',
          type: SystemType.RED_STAR,
          x: 0,
          y: 0,
          distance: 0,
        ),
      ),
    );
    final waypoints = await waypointsInJumpRadius(
      waypointCache: waypointCache,
      startSystem: 'A',
      maxJumps: 1,
    ).toList();
    expect(waypoints, [...aWaypoints, ...bWaypoints]);
  });
}
