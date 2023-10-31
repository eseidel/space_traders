import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/mine_scores.dart';
import 'package:cli/net/auth.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final countLimit = int.tryParse(argResults['limit'] as String);
  if (countLimit == null) {
    throw ArgumentError.value(
      argResults['limit'],
      'limit',
      'Must be an integer.',
    );
  }

  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => 0);
  final systems = await SystemsCache.load(fs);
  final charting = ChartingCache.load(fs);
  final construction = ConstructionCache.load(fs);
  final waypointCache = WaypointCache(api, systems, charting, construction);
  final agentCache = AgentCache.loadCached(fs)!;
  final hqSystem = agentCache.agent.headquartersSymbol.systemSymbol;
  final marketCache = MarketCache(waypointCache);

  final targets =
      await evaluteWaypointsForSiphoning(waypointCache, marketCache, hqSystem);

  final table = Table(
    header: ['Waypoint', 'Market', 'Score'],
    style: const TableStyle(compact: true),
  );

  // Limit to only the closest for each.
  final seen = <WaypointSymbol>{};
  for (final target in targets) {
    if (seen.contains(target.target)) {
      continue;
    }
    // Only consider markets that trade all goods produced by the mine.
    if (!target.marketTradesAllProducedGoods) {
      logger
        ..warn(
            '${target.market} does not trade ${target.goodsMissingFromMarket}'
            ' produced by ${target.target}')
        ..info('${target.market} trades ${target.marketGoods}');
      continue;
    }
    seen.add(target.target);
    table.add([
      target.target.toString(),
      target.market.toString(),
      target.score,
    ]);
    if (seen.length >= countLimit) {
      break;
    }
  }
  logger.info(table.toString());

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs: (parser) {
      parser.addOption(
        'limit',
        abbr: 'l',
        help: 'Limit the number of markets to look at.',
        defaultsTo: '10',
      );
    },
  );
}
