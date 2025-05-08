import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';
import 'package:collection/collection.dart';

String _typeName(SystemType type) {
  if (type.value.endsWith('_STAR')) {
    return type.value.substring(0, type.value.length - '_STAR'.length);
  }
  return type.value;
}

Future<void> command(Database db, ArgResults argResults) async {
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);
  final chartingSnapshot = await db.charting.snapshotAllRecords();
  final marketListings = await db.marketListings.snapshotAll();
  final shipyardListings = await ShipyardListingSnapshot.load(db);

  // Having market data means it's charted (either by us or someone else).
  // final systemsWithMarketPrices =
  //     marketListings.waypointSymbols.map((e) => e.systemSymbol).toSet();
  final systemsWithMarketPrices = marketListings.systemsWithAtLeastNMarkets(5);
  final systemSymbols = systemsWithMarketPrices;
  final table = Table(
    header: [
      'Symbol',
      'Type',
      'Market\nListing',
      'Market\nPrice',
      'Shipyard\nListing',
      'Shipyard\nPrice',
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
  final chartedWaypointsBySystem = chartingSnapshot.records
      .where((r) => r.isCharted)
      .groupListsBy((r) => r.waypointSymbol.system);

  for (final systemSymbol in systemSymbols) {
    final system = await db.systems.systemRecordBySymbol(systemSymbol);
    final waypoints = await db.systems.waypointsInSystem(systemSymbol);
    final records = chartedWaypointsBySystem[systemSymbol] ?? [];
    final chartedSymbols = records.map((r) => r.waypointSymbol).toSet();
    final waypointCount = waypoints.length;
    final asteroidSymbols = waypoints
        .where((w) => w.isAsteroid)
        .map((a) => a.symbol);
    final otherSymbols = waypoints
        .where((w) => !w.isAsteroid)
        .map((a) => a.symbol);
    final chartedAsteroids = asteroidSymbols.where(chartedSymbols.contains);
    final chartedOther = otherSymbols.where(chartedSymbols.contains);

    table.add([
      systemSymbol.systemName,
      _typeName(system!.type),
      marketListings.listingsInSystem(systemSymbol).length,
      marketPrices.waypointSymbolsInSystem(systemSymbol).length,
      shipyardListings.listingsInSystem(systemSymbol).length,
      shipyardPrices.waypointSymbolsInSystem(systemSymbol).length,
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

  final systemConnectivity = await loadSystemConnectivity(db);
  final hqSystemSymbol = await myHqSystemSymbol(db);
  final reachableSystems = systemConnectivity.systemsReachableFrom(
    hqSystemSymbol,
  );

  final systemsWithCharts = reachableSystems.where(
    (s) => (chartedWaypointsBySystem[s] ?? []).isNotEmpty,
  );
  logger.info(
    '${systemsWithCharts.length} systems with 1+ charts of '
    '${reachableSystems.length} known reachable.',
  );
}

void main(List<String> args) async {
  await runOffline(args, command);
}
