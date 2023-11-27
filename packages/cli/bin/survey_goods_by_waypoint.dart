import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/mine_scores.dart';

class _Stats {
  Set<TradeSymbol> tradeSymbols = {};
  int count = 0;
}

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final surveys = await db.allSurveys();
  final staticCaches = StaticCaches.load(fs);
  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);
  final systems = SystemsCache.load(fs)!;

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

  final extractionMounts = {
    staticCaches.mounts[ShipMountSymbolEnum.MINING_LASER_I]!,
  };

  for (final waypointSymbol in statsByWaypoint.keys) {
    final stats = statsByWaypoint[waypointSymbol]!;
    final tradeSymbolsString =
        stats.tradeSymbols.map((tradeSymbol) => tradeSymbol.toString()).toList()
          ..sort()
          ..join(', ');
    final waypointType = systems.waypoint(waypointSymbol).type;
    final expectedSymbols = expectedGoodsForWaypoint(
      waypointType,
      chartingCache[waypointSymbol]?.traitSymbols ?? {},
      extractionMounts: extractionMounts,
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
    final values = chartingCache[waypointSymbol];
    logger.info('$waypointSymbol: $waypointType '
        '$tradeSymbolsString ${values?.traitSymbols} '
        '(${stats.count})');
  }

  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
