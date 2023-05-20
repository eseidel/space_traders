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
  final systemWaypoints = await waypointsInSystem(api, hq.system).toList();

  final myShips = await allMyShips(api).toList();
  final ship = logger.chooseOne(
    'Which ship?',
    choices: myShips,
    display: (ship) => shipDescription(ship, systemWaypoints),
  );
  await api.fleet.dockShip(ship.symbol);
  logger.info('Docked.');
}
