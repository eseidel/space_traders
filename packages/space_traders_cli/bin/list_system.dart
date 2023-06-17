import 'package:file/local.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);
  final hq = await waypointCache.getAgentHeadquarters();
  final waypoints = await waypointCache.waypointsInSystem(hq.systemSymbol);
  printWaypoints(waypoints);
}
