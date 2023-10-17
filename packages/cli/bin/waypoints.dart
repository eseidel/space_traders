import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final chartingCache = ChartingCache.load(fs);
  final waypointCount = chartingCache.waypointCount;
  logger.info('Waypoint count: $waypointCount');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
