import 'package:cli/cache/systems_cache.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/nav/system_pathing.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('SystemPathing smoke test', () {
    final start = WaypointSymbol.fromString('X-A-A');
    final end = WaypointSymbol.fromString('X-B-B');

    final systems = [
      System.test(
        start.system,
        waypoints: [SystemWaypoint.test(start, type: WaypointType.JUMP_GATE)],
      ),
      System.test(
        end.system,
        position: const SystemPosition(10, 0),
        waypoints: [SystemWaypoint.test(end, type: WaypointType.JUMP_GATE)],
      ),
    ];
    final systemsCache = SystemsSnapshot(systems);
    final systemConnectivity = SystemConnectivity.test({
      start: {end},
    });

    final path = findWaypointPathJumpsOnly(
      systemsCache,
      systemConnectivity,
      start,
      end,
    );
    expect(path, [start, end]);
  });
}
