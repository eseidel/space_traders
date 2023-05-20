import 'package:file/local.dart';
import 'package:space_traders_cli/actions.dart';
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

  final waypoint = logger.chooseOne(
    'To where?',
    choices: systemWaypoints,
    display: waypointDescription,
  );

  final shouldDock = logger.confirm('Wait to dock?', defaultValue: true);

  final navigateResult = await navigateTo(api, ship, waypoint);
  final eta = navigateResult.nav.route.arrival;
  final flightTime = eta.difference(DateTime.now());
  logger.info('Expected in $flightTime.');
  if (shouldDock) {
    logger.info('Waiting to dock...');
    await Future<void>.delayed(flightTime);
    await api.fleet.dockShip(ship.symbol);
    logger.info('Docked.');
  }
}
