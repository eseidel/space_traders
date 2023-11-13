import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/waypoint_connectivity.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final staticCache = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final agentCache = AgentCache.load(fs)!;
  final hqSystem = agentCache.headquartersSymbol.systemSymbol;
  final fuelCapacity =
      staticCache.shipyardShips[ShipType.COMMAND_FRIGATE]!.frame.fuelCapacity;

  logger
      .info('Exploring waypoint clusters in $hqSystem with $fuelCapacity fuel');
  final connectivity = WaypointConnectivity.fromSystemAndFuelCapacity(
    systemsCache,
    hqSystem,
    fuelCapacity,
  );
  final clusterIds = connectivity.clusterIds;
  logger.info('Found ${clusterIds.length} clusters');
  for (final clusterId in clusterIds) {
    final waypointSymbols = connectivity.waypointSymbolsInCluster(clusterId);
    final plural = waypointSymbols.length == 1 ? '' : 's';
    logger.info('${waypointSymbols.length} waypoint$plural:');
    for (final waypointSymbol in waypointSymbols) {
      final waypoint = systemsCache.waypointFromSymbol(waypointSymbol);
      logger.info(
        '  ${waypointSymbol.waypoint.padRight(11)} '
        '@ ${waypoint.x},${waypoint.y}',
      );
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
