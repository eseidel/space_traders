import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final chartingCache = ChartingCache.load(fs);
  final waypointCount = chartingCache.waypointCount;
  logger.info('Waypoint count: $waypointCount');

  final traitCounts = <WaypointTraitSymbolEnum, int>{};
  for (final value in chartingCache.values) {
    for (final trait in value.traitSymbols) {
      traitCounts[trait] = (traitCounts[trait] ?? 0) + 1;
    }
  }
  for (final trait in WaypointTraitSymbolEnum.values) {
    final count = traitCounts[trait];
    if (count != null) {
      logger.info('Waypoint trait $trait: $count');
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
