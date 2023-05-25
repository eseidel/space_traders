import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final waypointCache = WaypointCache(api);
  final agentResult = await api.agents.getMyAgent();

  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemResponse = await api.systems.getSystem(hq.system);
  final system = systemResponse!.data;

  final jumpGateWaypoint = system.waypoints
      .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);

  final jumpGateResponse =
      await api.systems.getJumpGate(system.symbol, jumpGateWaypoint!.symbol);
  final jumpGate = jumpGateResponse!.data;
  for (final system in jumpGate.connectedSystems) {
    logger.info('${system.symbol} - ${system.distance}');
    final waypoints = await waypointCache.waypointsInSystem(system.symbol);
    printWaypoints(waypoints, indent: '  ');
  }
}
