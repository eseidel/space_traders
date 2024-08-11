import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

class _ChartingCounts {
  _ChartingCounts({
    required this.symbol,
    required this.uncharted,
    required this.asteroids,
    required this.jumpgates,
  });

  final SystemSymbol symbol;
  final int uncharted;
  final int asteroids;
  final int jumpgates;
}

_ChartingCounts _count(ChartingSnapshot charts, System system) {
  var unchartedCount = 0;
  var jumpgateCount = 0;
  var asteroidCount = 0;
  for (final waypoint in system.waypoints) {
    if (!isUncharted(charts, waypoint)) {
      continue;
    }
    unchartedCount++;
    if (waypoint.isJumpGate) {
      jumpgateCount++;
    }
    if (waypoint.isAsteroid) {
      asteroidCount++;
    }
  }
  return _ChartingCounts(
    symbol: system.symbol,
    uncharted: unchartedCount,
    asteroids: asteroidCount,
    jumpgates: jumpgateCount,
  );
}

bool isUncharted(ChartingSnapshot charts, SystemWaypoint waypoint) {
  final maybeCharted = charts[waypoint.symbol]?.isCharted;
  return maybeCharted == null || !maybeCharted;
}

/// Walks our known system graph, starting from HQ and prints systems needing
/// exploration.
Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final systemConnectivity = await loadSystemConnectivity(db);
  final systemsCache = SystemsCache.load(fs);
  final charts = await ChartingSnapshot.load(db);

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

  var totalUncharted = 0;
  var totalAsteroids = 0;
  var totalJumpgates = 0;
  for (final (systemSymbol, jumps) in connectedSystems) {
    final counts = _count(charts, systemsCache[systemSymbol]);
    logger.info(
      '${systemSymbol.system.padRight(9)} '
      '${counts.uncharted} uncharted, ${counts.asteroids} asteroids, '
      '${counts.jumpgates} jumpgates, ($jumps jumps)',
    );
    totalUncharted += counts.uncharted;
    totalAsteroids += counts.asteroids;
    totalJumpgates += counts.jumpgates;
  }
  logger.info(
    'Total: $totalUncharted uncharted, $totalAsteroids asteroids, '
    '$totalJumpgates jumpgates',
  );
}

void main(List<String> args) async {
  await runOffline(args, command);
}
