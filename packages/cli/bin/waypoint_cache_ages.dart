import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final systemsCache = SystemsCache.load(fs);
  final chartingSnapshot = await ChartingSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final shipyardPrices = await ShipyardPriceSnapshot.load(db);

  final waypoints = systemsCache.waypointsInSystem(startSystemSymbol);

  final table = Table(
    header: ['Waypoint', 'Market', 'Shipyard', 'Construction', 'Chart'],
    style: const TableStyle(compact: true),
  );

  String cacheString(Duration? age, {required bool expected}) {
    if (age == null) {
      if (expected) {
        return '❌';
      }
      return '';
    }
    return approximateDuration(age);
  }

  for (final waypoint in waypoints) {
    final waypointSymbol = waypoint.symbol;
    final values = chartingSnapshot[waypointSymbol]?.values;
    final marketAge = marketPrices.cacheAgeFor(waypointSymbol);
    final shipyardAge = shipyardPrices.cacheAgeFor(waypointSymbol);
    final constructionAge = constructionSnapshot.cacheAgeFor(waypointSymbol);

    table.add([
      waypointSymbol.waypoint,
      cacheString(marketAge, expected: values?.hasMarket ?? false),
      cacheString(shipyardAge, expected: values?.hasShipyard ?? false),
      if (constructionAge == null) '' else approximateDuration(constructionAge),
      if (values == null) '?' else '✅',
    ]);
  }

  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(args, command);
}
