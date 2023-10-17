import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final chartingCache = ChartingCache.load(fs);
  final waypointCount = chartingCache.waypointCount;
  logger.info('Waypoint count: $waypointCount');

  final traitCounts = <String, int>{};
  for (final waypoint in chartingCache.waypoints) {
    for (final trait in waypoint.traits) {
      traitCounts[trait] = (traitCounts[trait] ?? 0) + 1;
    }
  }
  for (final trait in WaypointTraitSymbolEnum.values) {
    final count = traitCounts[trait.value];
    if (count != null) {
      logger.info('Waypoint trait ${trait.value}: $count');
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
