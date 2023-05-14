import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

Future<void> printAvailableShipsAt(Api api, Waypoint waypoint) async {
  if (!waypoint.hasShipyard) {
    return;
  }
  logger.info('Ships types available at ${waypoint.symbol}:');

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  for (final shipType in shipyardResponse!.data.shipTypes) {
    logger.info('  ${shipType.type}');
  }
  final ships = shipyardResponse.data.ships;
  if (ships.isEmpty) {
    return;
  }
  logger.info('Ships available at ${waypoint.symbol}:');
  for (final ship in ships) {
    logger.info('  ${ship.type} - ${ship.purchasePrice}');
  }
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);

  final agentResult = await api.agents.getMyAgent();

  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);

  final myShips = await allMyShips(api).toList();
  logger.info('Current ships:');
  printShips(myShips, systemWaypoints);
  logger.info('');

  for (final waypoint in systemWaypoints) {
    await printAvailableShipsAt(api, waypoint);
  }
}
