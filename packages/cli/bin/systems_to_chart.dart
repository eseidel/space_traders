import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

/// Walks our known system graph, starting from HQ and prints systems needing
/// exploration.
Future<void> command(FileSystem fs, ArgResults argResults) async {
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final staticCaches = StaticCaches.load(fs);
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionCache = ConstructionCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionCache);
  final systemsCache = SystemsCache.load(fs)!;
  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);

  int unchartedWaypointCount(SystemSymbol systemSymbol) {
    return systemsCache[systemSymbol]
        .waypoints
        .where((w) => chartingCache[w.waypointSymbol] == null)
        .length;
  }

  final connectedSystems = systemConnectivity
      .systemSymbolsInJumpRadius(
        systemsCache,
        startSystem: startSystemSymbol,
        maxJumps: 3,
      )
      .toList();
  if (connectedSystems.isEmpty) {
    logger.info('No systems connected to $startSystemSymbol.');
    return;
  }

  for (final (systemSymbol, jumps) in connectedSystems) {
    final unchartedCount = unchartedWaypointCount(systemSymbol);
    if (unchartedCount == 0) {
      continue;
    }
    logger.info(
      '${systemSymbol.system.padRight(9)} '
      '$unchartedCount uncharted ($jumps jumps)',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
