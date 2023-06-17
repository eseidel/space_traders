import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final ships = await allMyShips(api).toList();

  // get all the ships
  // count them by type.
  final typeCounts = <ShipFrameSymbolEnum, int>{};
  for (final ship in ships) {
    final type = ship.frame.symbol;
    typeCounts[type] = (typeCounts[type] ?? 0) + 1;
  }

  for (final type in typeCounts.keys) {
    logger.info('$type: ${typeCounts[type]}');
  }

  // list them all.
  final shipWaypoints = await waypointsForShips(waypointCache, ships);
  for (final ship in ships) {
    logger.info(shipDescription(ship, shipWaypoints));
  }
}
