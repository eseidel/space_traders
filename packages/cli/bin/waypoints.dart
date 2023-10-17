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
  final symbols = WaypointTraitSymbolEnum.values.toList()
    ..sort((a, b) {
      final aCount = traitCounts[b] ?? 0;
      final bCount = traitCounts[a] ?? 0;
      return aCount.compareTo(bCount);
    });

  for (final trait in symbols) {
    final count = traitCounts[trait];
    if (count != null) {
      logger.info('$trait: $count');
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
