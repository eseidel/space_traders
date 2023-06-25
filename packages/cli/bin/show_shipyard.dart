import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.waypoints, myShips);
  final shipyardWaypoints =
      await caches.waypoints.shipyardWaypointsForSystem(ship.nav.systemSymbol);

  final waypoint = logger.chooseOne(
    'Which shipyard?',
    choices: shipyardWaypoints,
    display: waypointDescription,
  );

  final shipyardResponse =
      await api.systems.getShipyard(waypoint.systemSymbol, waypoint.symbol);
  final shipyard = shipyardResponse!.data;

  prettyPrintJson(shipyard.toJson());
}
