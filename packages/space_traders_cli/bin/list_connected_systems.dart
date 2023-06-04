import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);
  final hq = await waypointCache.getAgentHeadquarters();
  final jumpGate = await waypointCache.jumpGateForSystem(hq.systemSymbol);
  for (final system in jumpGate!.connectedSystems) {
    logger.info('${system.symbol} - ${system.distance}');
    final waypoints = await waypointCache.waypointsInSystem(system.symbol);
    printWaypoints(waypoints, indent: '  ');
  }
}
