import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

/// Walks our known system graph, starting from HQ and prints systems needing
/// exploration.
Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final systemConnectivity = await loadSystemConnectivity(db);
  final systemsCache = SystemsCache.load(fs)!;
  final chartingSnapshot = await ChartingSnapshot.load(db);

  bool isUncharted(SystemWaypoint waypoint) {
    final maybeCharted = chartingSnapshot[waypoint.symbol]?.isCharted;
    return maybeCharted == null || !maybeCharted;
  }

  int unchartedWaypointCount(SystemSymbol systemSymbol) {
    return systemsCache[systemSymbol].waypoints.where(isUncharted).length;
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
