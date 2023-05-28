import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';

void printShipDetails(Ship ship, List<Waypoint> shipWaypoints) {
  logger.info(shipDescription(ship, shipWaypoints));
  logCargo(ship);

  prettyPrintJson(ship.toJson());
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final waypointCache = WaypointCache(api);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);
  final shipsWaypoints = await waypointsForShips(waypointCache, myShips);
  // TODO(eseidel): These are the wrong waypoints.
  printShipDetails(ship, shipsWaypoints);
}
