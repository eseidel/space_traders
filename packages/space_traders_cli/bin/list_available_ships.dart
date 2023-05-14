import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void printAvailableShipsAt(Api api, Waypoint waypoint) async {
  if (!waypoint.hasShipyard) {
    return;
  }
  print("Ships types available at ${waypoint.symbol}:");

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  for (var shipType in shipyardResponse!.data.shipTypes) {
    print("  ${shipType.type}");
  }
  final ships = shipyardResponse.data.ships;
  if (ships.isEmpty) {
    return;
  }
  print("Ships available at ${waypoint.symbol}:");
  for (var ship in ships) {
    print("  ${ship.type} - ${ship.purchasePrice}");
  }
}

void main(List<String> args) async {
  final fs = const LocalFileSystem();
  final api = defaultApi(fs);

  final agentResult = await api.agents.getMyAgent();

  final agent = agentResult!.data;
  final hq = parseWaypointString(agent.headquarters);
  final systemWaypoints = await waypointsInSystem(api, hq.system);

  final myShips = await allMyShips(api).toList();
  print("Current ships:");
  printShips(myShips, systemWaypoints);
  print("");

  for (var waypoint in systemWaypoints) {
    printAvailableShipsAt(api, waypoint);
  }
}
