import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';

void main(List<String> args) async {
  await run(args, command);
}

Future<void> command(FileSystem fs, Api api, Caches caches) async {
  final typeCounts = caches.ships.frameCounts;
  for (final type in typeCounts.keys) {
    logger.info('$type: ${typeCounts[type]}');
  }
  final ships = caches.ships.ships;
  final shipWaypoints = await waypointsForShips(caches.waypoints, ships);
  for (final ship in ships) {
    logger.info(shipDescription(ship, shipWaypoints));
  }
}
