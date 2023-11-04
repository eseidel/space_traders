import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

class _Stats {
  Set<TradeSymbol> tradeSymbols = {};
  int count = 0;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final surveys = await db.allSurveys();
  final staticCaches = StaticCaches.load(fs);
  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);

  // For each waypoint, record what tradeSymbols are found there.
  final statsByWaypoint = <WaypointSymbol, _Stats>{};
  for (final survey in surveys) {
    final stats = statsByWaypoint.putIfAbsent(
      survey.survey.waypointSymbol,
      _Stats.new,
    );
    stats.tradeSymbols.addAll(survey.survey.tradeSymbols);
    stats.count++;
  }

  for (final waypointSymbol in statsByWaypoint.keys) {
    final stats = statsByWaypoint[waypointSymbol]!;
    final tradeSymbolsString = stats.tradeSymbols
        .map((tradeSymbol) => tradeSymbol.toString())
        .join(', ');
    final values = chartingCache.valuesForSymbol(waypointSymbol);
    logger.info('$waypointSymbol: $tradeSymbolsString ${values?.traitSymbols} '
        '(${stats.count})');
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
