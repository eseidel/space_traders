import 'package:cli/cache/market_listing_snapshot.dart';
import 'package:cli/cli.dart';
import 'package:cli_table/cli_table.dart';

Map<String, dynamic> rightAlign(Object? content) => <String, dynamic>{
  'content': content.toString(),
  'hAlign': HorizontalAlign.right,
};

Future<void> command(Database db, ArgResults argResults) async {
  final chartingSnapshot = await db.charting.snapshotAllRecords();
  final marketListings = await MarketListingSnapshot.load(db);
  final systemsCache = await db.systems.snapshotAllSystems();

  // Walk all charting records.
  // Record the number of known waypoints by type.
  // Record if it has a market.
  final waypointsByType = <WaypointType, int>{};
  final waypointsWithMarket = <WaypointType, int>{};
  for (final record in chartingSnapshot.records) {
    final waypoint = systemsCache.waypoint(record.waypointSymbol);
    waypointsByType[waypoint.type] = (waypointsByType[waypoint.type] ?? 0) + 1;
    if (marketListings[record.waypointSymbol] != null) {
      waypointsWithMarket[waypoint.type] =
          (waypointsWithMarket[waypoint.type] ?? 0) + 1;
    }
  }
  // Print the results.
  final table = Table(
    header: ['Waypoint Type', '%', 'Count', 'Markets'],
    style: const TableStyle(compact: true),
  );
  for (final type in waypointsByType.keys) {
    final waypointCount = waypointsByType[type]!;
    final marketCount = waypointsWithMarket[type] ?? 0;
    final percentWithMarket = (marketCount / waypointCount * 100).round();
    table.add([
      type.value,
      rightAlign(percentWithMarket),
      rightAlign(waypointCount),
      rightAlign(marketCount),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
