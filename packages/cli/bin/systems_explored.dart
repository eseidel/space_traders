import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  final chartingCache = ChartingCache.load(fs, waypointTraits);
  final systemsCache = SystemsCache.load(fs)!;

  // Having market price data is a good proxy for if we've explored something.
  final systemsWithMarketPrices =
      marketPrices.waypointSymbols.map((e) => e.systemSymbol).toSet();
  final table = Table(
    header: [
      'Symbol',
      'Markets',
      'Shipyards',
      'Charted',
      'Asteroids',
    ],
    style: const TableStyle(compact: true),
  );

  String progressString(int count, int total) {
    if (count == total) return '✅';
    return '$count/$total';
  }

  for (final systemSymbol in systemsWithMarketPrices) {
    final system = systemsCache[systemSymbol];
    final chartedSymbols =
        chartingCache.waypointsWithChartInSystem(systemSymbol);
    final waypointCount = system.waypoints.length;
    final asteroidSymbols = system.waypoints
        .where((w) => w.isAsteroid)
        .map((a) => a.waypointSymbol);
    final chartedAsteroids = asteroidSymbols.where(chartedSymbols.contains);

    table.add([
      systemSymbol.systemName,
      marketPrices.waypointsWithPricesInSystem(systemSymbol).length,
      shipyardPrices.waypointsWithPricesInSystem(systemSymbol).length,
      progressString(chartedSymbols.length, waypointCount),
      progressString(chartedAsteroids.length, asteroidSymbols.length),
    ]);
  }

  logger
    ..info(table.toString())
    ..info(
      '${systemsWithMarketPrices.length} reachable systems '
      'with market prices.',
    );

  final jumpGateCache = JumpGateCache.load(fs);
  final constructionCache = ConstructionCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionCache);
  final agentCache = AgentCache.load(fs)!;
  final headquartersSystemSymbol = agentCache.headquartersSystemSymbol;
  final reachableSystems =
      systemConnectivity.systemsReachableFrom(headquartersSystemSymbol);
  logger.info('${reachableSystems.length} systems known reachable from HQ.');

  final systemsWithCharts = reachableSystems
      .where((s) => chartingCache.waypointsWithChartInSystem(s).isNotEmpty);
  logger.info('${systemsWithCharts.length} reachable systems with charts.');

  final unexploredSystems = reachableSystems
      .where((s) => chartingCache.waypointsWithChartInSystem(s).isEmpty);
  logger.info('${unexploredSystems.length} reachable systems unexplored:');
  for (final system in unexploredSystems) {
    logger.info('  $system');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
