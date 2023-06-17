import 'package:file/local.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final myShips = await allMyShips(api).toList();
  final ship = await chooseShip(api, waypointCache, myShips);

  final shipyardWaypoints =
      await waypointCache.shipyardWaypointsForSystem(ship.nav.systemSymbol);

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
