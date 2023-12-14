import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);
  final waypointTraits = WaypointTraitCache.load(fs);
  final chartingCache = ChartingCache.load(fs, waypointTraits);

  // Having market price data is a good proxy for if we've explored something.
  final systemsWithMarketPrices =
      marketPrices.waypointSymbols.map((e) => e.systemSymbol).toSet();
  final table = Table(
    header: [
      'Symbol',
      'Markets',
      'Shipyards',
      'Charts',
    ],
    style: const TableStyle(compact: true),
  );

  for (final system in systemsWithMarketPrices) {
    table.add([
      system.systemName,
      marketPrices.waypointsWithPricesInSystem(system).length,
      shipyardPrices.waypointsWithPricesInSystem(system).length,
      chartingCache.waypointsWithChartInSystem(system).length,
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
