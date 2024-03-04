import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

// This is a bit of a cheat.  It appears starter systems all have over 20
// non-asteroid waypoints.  We can use this to find starter systems.
/// Returns the set of systems we should prefer to chart.
Set<SystemSymbol> findInterestingSystems(SystemsCache systemsCache) {
  final allSystems = systemsCache.systems;
  // All systems with over 20 non-asteroid waypoints:
  return allSystems
      .where(
        (system) => system.waypoints.where((w) => !w.isAsteroid).length > 20,
      )
      .map((system) => system.symbol)
      .toSet();
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);
  final systemsCache = SystemsCache.load(fs)!;

  final systems = await SystemsCache.loadOrFetch(fs);
  final charting = ChartingCache(db);
  final construction = ConstructionCache(db);
  final waypointTraits = WaypointTraitCache.load(fs);
  final waypointCache =
      WaypointCache(api, systems, charting, construction, waypointTraits);

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
