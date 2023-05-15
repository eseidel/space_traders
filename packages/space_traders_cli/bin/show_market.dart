import 'package:file/local.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final agentResult = await api.agents.getMyAgent();
  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);
  final marketplaceWaypoints =
      systemWaypoints.where((w) => w.hasMarketplace).toList();

  final waypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );

  final marketResponse =
      await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
  final market = marketResponse!.data;
  prettyPrintJson(market.toJson());
}
