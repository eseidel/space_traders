import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';
import 'package:test/test.dart';

class MockWaypointCache extends Mock implements WaypointCache {}

class MockSystemsCache extends Mock implements SystemsCache {}

void main() {
  test('waypointsInJumpRadius', () async {
    final WaypointCache waypointCache = MockWaypointCache();
    final SystemsCache systemsCache = MockSystemsCache();
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
    when(() => systemsCache.connectedSystems('A')).thenAnswer(
      (invocation) => [
        ConnectedSystem(
          symbol: 'B',
          sectorSymbol: 'B',
          type: SystemType.RED_STAR,
          x: 0,
          y: 0,
          distance: 0,
        ),
      ],
    );
    final waypoints = await waypointsInJumpRadius(
      systemsCache: systemsCache,
      waypointCache: waypointCache,
      startSystem: 'A',
      maxJumps: 1,
    ).toList();
    expect(waypoints, [...aWaypoints, ...bWaypoints]);
  });

  test('systemSymbolsInJumpRadius depth', () async {
    final SystemsCache systemsCache = MockSystemsCache();
    final expectedSystems = ['A', 'B', 'C', 'D', 'E'];
    var index = 0;
    for (final system in expectedSystems) {
      final neighbors = [
        if (index < expectedSystems.length - 1)
          ConnectedSystem(
            symbol: expectedSystems[index + 1],
            sectorSymbol: 'S',
            type: SystemType.RED_STAR,
            x: 0,
            y: 0,
            distance: 0,
          ),
        if (index > 0)
          ConnectedSystem(
            symbol: expectedSystems[index - 1],
            sectorSymbol: 'S',
            type: SystemType.RED_STAR,
            x: 0,
            y: 0,
            distance: 0,
          ),
      ];
      when(() => systemsCache.connectedSystems(any(that: equals(system))))
          .thenAnswer(
        (invocation) => neighbors,
      );
      index++;
    }

    final systems = await systemSymbolsInJumpRadius(
      systemsCache: systemsCache,
      startSystem: 'A',
      maxJumps: 5,
    ).toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });

  test('systemSymbolsInJumpRadius all connected', () async {
    final SystemsCache systemsCache = MockSystemsCache();
    final expectedSystems = ['A', 'B', 'C', 'D', 'E'];
    for (final system in expectedSystems) {
      final neighbors = expectedSystems
          .where((s) => s != system)
          .map(
            (s) => ConnectedSystem(
              symbol: s,
              sectorSymbol: 'S',
              type: SystemType.RED_STAR,
              x: 0,
              y: 0,
              distance: 0,
            ),
          )
          .toList();
      when(() => systemsCache.connectedSystems(any(that: equals(system))))
          .thenAnswer(
        (invocation) => neighbors,
      );
    }

    final systems = await systemSymbolsInJumpRadius(
      systemsCache: systemsCache,
      startSystem: 'A',
      maxJumps: 5,
    ).toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });
}
