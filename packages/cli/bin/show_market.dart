import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final myShips = caches.ships.ships;
  final ship = await chooseShip(api, caches.systems, myShips);

  final marketplaceWaypoints =
      await caches.waypoints.marketWaypointsForSystem(ship.systemSymbol);

  final waypoint = logger.chooseOne(
    'Which marketplace?',
    choices: marketplaceWaypoints,
    display: waypointDescription,
  );

  final market = await caches.markets.marketForSymbol(waypoint.waypointSymbol);
  prettyPrintJson(market!.toJson());
}
