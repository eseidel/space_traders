import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

String _typeName(SystemType type) {
  if (type.value.endsWith('_STAR')) {
    return type.value.substring(0, type.value.length - '_STAR'.length);
  }
  return type.value;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);
  final chartingSnapshot = await ChartingSnapshot.load(db);
  final systemsCache = SystemsCache.load(fs)!;

  // Having market price data is a good proxy for if we've explored something.
  final systemsWithMarketPrices =
      marketPrices.waypointSymbols.map((e) => e.systemSymbol).toSet();
  final systemSymbols = systemsWithMarketPrices;
  final table = Table(
    header: [
      'Symbol',
      'Type',
      'Markets',
      'Shipyards',
      'Waypoints',
      'Charts\nOther',
      'Charts\nAsteroids',
    ],
    style: const TableStyle(compact: true),
  );

  String progressString(int count, int total) {
    if (count == total) return '✅';
    return '$count/$total';
  }

  // We can move this index into another object if other scripts need similar.
  final chartedWaypointsBySystem =
      chartingSnapshot.records.where((r) => r.isCharted).groupListsBy(
            (r) => r.waypointSymbol.systemSymbol,
          );

  for (final systemSymbol in systemSymbols) {
    final system = systemsCache[systemSymbol];
    final records = chartedWaypointsBySystem[systemSymbol] ?? [];
    final chartedSymbols = records.map((r) => r.waypointSymbol).toSet();
    final waypointCount = system.waypoints.length;
    final asteroidSymbols = system.waypoints
        .where((w) => w.isAsteroid)
        .map((a) => a.waypointSymbol);
    final otherSymbols = system.waypoints
        .where((w) => !w.isAsteroid)
        .map((a) => a.waypointSymbol);
    final chartedAsteroids = asteroidSymbols.where(chartedSymbols.contains);
    final chartedOther = otherSymbols.where(chartedSymbols.contains);

    table.add([
      systemSymbol.systemName,
      _typeName(system.type),
      marketPrices.waypointsWithPricesInSystem(systemSymbol).length,
      shipyardPrices.waypointsWithPricesInSystem(systemSymbol).length,
      waypointCount,
      progressString(chartedOther.length, otherSymbols.length),
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
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);
  final agentCache = AgentCache.load(fs)!;
  final headquartersSystemSymbol = agentCache.headquartersSystemSymbol;
  final reachableSystems =
      systemConnectivity.systemsReachableFrom(headquartersSystemSymbol);

  final systemsWithCharts = reachableSystems
      .where((s) => (chartedWaypointsBySystem[s] ?? []).isNotEmpty);
  logger.info(
    '${systemsWithCharts.length} systems with 1+ charts of '
    '${reachableSystems.length} known reachable.',
  );

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
