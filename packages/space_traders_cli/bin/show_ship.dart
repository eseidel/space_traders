import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/printing.dart';

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
