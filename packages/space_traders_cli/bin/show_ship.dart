import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/cli.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';

void printShipDetails(Ship ship, List<Waypoint> shipWaypoints) {
  logger.info(shipDescription(ship, shipWaypoints));
  logCargo(ship);

  prettyPrintJson(ship.toJson());
}

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.waypoints, myShips);
  final shipsWaypoints = await waypointsForShips(caches.waypoints, myShips);
  printShipDetails(ship, shipsWaypoints);
}
