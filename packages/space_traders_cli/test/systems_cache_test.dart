import 'package:file/memory.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:test/test.dart';

void main() {
  test('systemSymbolsInJumpRadius depth', () async {
    final expectedSystems = ['A', 'B', 'C', 'D', 'E'];
    const jumpDistance = 200;
    var i = 0;
    final inputSystems = [
      for (final system in expectedSystems)
        System(
          symbol: system,
          sectorSymbol: 'S',
          type: SystemType.RED_STAR,
          x: i++ * (jumpDistance - 1),
          y: 0,
          waypoints: [
            SystemWaypoint(
              symbol: 'S-$system-J',
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            )
          ],
        ),
    ];

    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(systems: inputSystems, fs: fs);
    final systems = await systemsCache
        .systemSymbolsInJumpRadius(
          startSystem: 'A',
          maxJumps: 5,
        )
        .toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });

  test('systemSymbolsInJumpRadius all connected', () async {
    final expectedSystems = ['S-A', 'S-B', 'S-C', 'S-D', 'S-E'];
    final inputSystems = [
      for (final system in expectedSystems)
        System(
          symbol: system,
          sectorSymbol: 'S',
          type: SystemType.RED_STAR,
          x: 0,
          y: 0,
          waypoints: [
            SystemWaypoint(
              symbol: 'S-$system-J',
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            )
          ],
        ),
    ];

    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(systems: inputSystems, fs: fs);

    final systems = await systemsCache
        .systemSymbolsInJumpRadius(
          startSystem: 'S-A',
          maxJumps: 5,
        )
        .toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });
}
