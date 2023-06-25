import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

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
