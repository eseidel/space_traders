import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void printShipDetails(Ship ship, List<Waypoint> shipWaypoints) {
  logger.info(shipDescription(ship, shipWaypoints));
  logCargo(ship);

  prettyPrintJson(ship.toJson());
}

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);
  final shipsWaypoints = await waypointsForShips(waypointCache, myShips);
  printShipDetails(ship, shipsWaypoints);
}