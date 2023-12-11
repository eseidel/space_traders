import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/printing.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);
  final constrctionCache = ConstructionCache.load(fs);
  final marketPrices = MarketPrices.load(fs);
  final shipyardPrices = ShipyardPrices.load(fs);

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
    final waypointSymbol = waypoint.waypointSymbol;
    final values = chartingCache[waypointSymbol];
    final marketAge = marketPrices.cacheAgeFor(waypointSymbol);
    final shipyardAge = shipyardPrices.cacheAgeFor(waypointSymbol);
    final constructionAge = constrctionCache.cacheAgeFor(waypointSymbol);

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
