import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/plan/extraction_score.dart';

class _Stats {
  Set<TradeSymbol> tradeSymbols = {};
  int count = 0;
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final surveys = await db.allSurveys();
  final chartingSnapshot = await ChartingSnapshot.load(db);
  final systems = SystemsCache.load(fs);

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
    final tradeSymbolsString =
        stats.tradeSymbols.map((tradeSymbol) => tradeSymbol.toString()).toList()
          ..sort()
          ..join(', ');
    final waypointType = systems.waypoint(waypointSymbol).type;
    final expectedSymbols = expectedGoodsForWaypoint(
      waypointType,
      chartingSnapshot[waypointSymbol]?.values?.traitSymbols ?? {},
      ExtractionType.mine,
    );
    final missingSymbols = stats.tradeSymbols.difference(expectedSymbols);
    if (missingSymbols.isNotEmpty) {
      logger.warn(
        '$waypointSymbol, prediction missed: ${missingSymbols.toList()}',
      );
    }
    final extraSymbols = expectedSymbols.difference(stats.tradeSymbols);
    if (extraSymbols.isNotEmpty) {
      logger.warn(
        '$waypointSymbol, prediction had extra: ${extraSymbols.toList()}',
      );
    }
    final record = chartingSnapshot[waypointSymbol];
    logger.info(
      '$waypointSymbol: $waypointType '
      '$tradeSymbolsString ${record?.values?.traitSymbols} '
      '(${stats.count})',
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
