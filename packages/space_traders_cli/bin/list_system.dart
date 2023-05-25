import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);

  final agentResult = await api.agents.getMyAgent();

  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointCache.waypointsInSystem(hq.system);
  printWaypoints(systemWaypoints);
}
