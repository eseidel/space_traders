import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = await defaultApi(db, getPriority: () => networkPriorityLow);
  final systemsCache = SystemsCache.load(fs);

  final systems = await SystemsCache.loadOrFetch(fs);
  final charting = ChartingCache(db);
  final construction = ConstructionCache(db);
  final waypointTraits = WaypointTraitCache.load(fs);
  final waypointCache =
      WaypointCache(api, db, systems, charting, construction, waypointTraits);

  // Find all known reachable systems.
  // List ones we know are reachable but don't have any prices.
  final interestingSystemSymbols = findInterestingSystems(systemsCache);
  logger.info(
    'Found ${interestingSystemSymbols.length} '
    'interesting systems.',
  );

  for (final symbol in interestingSystemSymbols) {
    final waypoints = await waypointCache.waypointsInSystem(symbol);
    logger.info('Fetched ${waypoints.length} waypoints for $symbol.');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
