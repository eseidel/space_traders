import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final chartingSnapshot = await ChartingSnapshot.load(db);
  final waypointCount = chartingSnapshot.waypointCount;
  logger.info('Waypoint count: $waypointCount');

  final traitCounts = <WaypointTraitSymbol, int>{};
  for (final value in chartingSnapshot.values) {
    for (final trait in value.traitSymbols) {
      traitCounts[trait] = (traitCounts[trait] ?? 0) + 1;
    }
  }
  final symbols =
      WaypointTraitSymbol.values.toList()..sort((a, b) {
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
