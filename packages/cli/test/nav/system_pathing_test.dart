import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/nav/system_pathing.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('SystemPathing smoke test', () {
    final start = WaypointSymbol.fromString('X-A-A');
    final end = WaypointSymbol.fromString('X-B-B');

    final fs = MemoryFileSystem.test();
    final systemsCache = SystemsCache(
      [
        System(
          symbol: start.system,
          sectorSymbol: start.sector,
          x: 0,
          y: 0,
          type: SystemType.BLACK_HOLE,
          waypoints: [
            SystemWaypoint(
              symbol: start.waypoint,
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
        System(
          symbol: end.system,
          sectorSymbol: end.sector,
          x: 10,
          y: 0,
          type: SystemType.BLACK_HOLE,
          waypoints: [
            SystemWaypoint(
              symbol: end.waypoint,
              type: WaypointType.JUMP_GATE,
              x: 0,
              y: 0,
            ),
          ],
        ),
      ],
      fs: fs,
    );
    final systemConnectivity = SystemConnectivity.test({
      start: {end},
    });
    const shipSpeed = 30;

    final path = findWaypointPathJumpsOnly(
      systemsCache,
      systemConnectivity,
      start,
      end,
      shipSpeed,
    );
    expect(path, [start, end]);
  });
}
