import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  test('systemSymbolsInJumpRadius depth', () async {
    final systemStrings = ['S-A', 'S-B', 'S-C', 'S-D', 'S-E'];
    final expectedSystems = systemStrings.map(SystemSymbol.fromString).toList();
    const jumpDistance = 200;
    var i = 0;
    final inputSystems = [
      for (final system in expectedSystems)
        System(
          symbol: system.system,
          sectorSymbol: 'S',
          type: SystemType.RED_STAR,
          x: i++ * (jumpDistance - 1),
          y: 0,
          waypoints: [
            SystemWaypoint(
              symbol: '$system-J',
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
    ];

    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(inputSystems, fs: fs);
    final systems = systemsCache
        .systemSymbolsInJumpRadius(
          startSystem: SystemSymbol.fromString('S-A'),
          maxJumps: 5,
        )
        .toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });

  test('systemSymbolsInJumpRadius all connected', () async {
    final systemStrings = ['S-A', 'S-B', 'S-C', 'S-D', 'S-E'];
    final expectedSystems = systemStrings.map(SystemSymbol.fromString).toList();
    final inputSystems = [
      for (final system in expectedSystems)
        System(
          symbol: system.system,
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
            ),
          ],
        ),
    ];

    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(inputSystems, fs: fs);

    final systems = systemsCache
        .systemSymbolsInJumpRadius(
          startSystem: SystemSymbol.fromString('S-A'),
          maxJumps: 5,
        )
        .toList();
    final systemSymbols = systems.map((e) => e.$1).toList();
    expect(systemSymbols, expectedSystems);
  });

  test('SystemCache load http failure', () async {
    final fs = MemoryFileSystem();
    Future<http.Response> mockGet(Uri uri) async {
      return http.Response('Not Found', 404);
    }

    final logger = _MockLogger();
    try {
      await runWithLogger(
        logger,
        () => SystemsCache.load(fs, httpGet: mockGet),
      );
      fail('exception not thrown');
    } on ApiException catch (e) {
      expect(e.code, 404);
    }
  });
}
