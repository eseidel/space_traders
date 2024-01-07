import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

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

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();

  final systemsCache = SystemsCache.load(fs)!;
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final jumpGateCache = JumpGateCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);
  final agentCache = AgentCache.load(fs)!;
  final hqSystemSymbol = agentCache.headquartersSystemSymbol;
  final reachableSystems =
      systemConnectivity.systemsReachableFrom(hqSystemSymbol).toSet();

  // Find all known reachable systems.
  // List ones we know are reachable but don't have any prices.
  final interestingSystemSymbols = findInterestingSystems(systemsCache);
  final reachableInterestingSystemSymbols =
      reachableSystems.intersection(interestingSystemSymbols);
  logger.info(
    'Found ${reachableInterestingSystemSymbols.length} reachable '
    'interesting systems.',
  );

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
