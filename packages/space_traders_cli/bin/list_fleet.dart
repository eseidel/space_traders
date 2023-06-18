import 'package:file/local.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/printing.dart';

void main(List<String> args) async {
  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

  final ships = await allMyShips(api).toList();
  final shipCache = ShipCache(ships);

  final typeCounts = shipCache.frameCounts;
  for (final type in typeCounts.keys) {
    logger.info('$type: ${typeCounts[type]}');
  }

  final shipWaypoints = await waypointsForShips(waypointCache, ships);
  for (final ship in ships) {
    logger.info(shipDescription(ship, shipWaypoints));
  }
}
