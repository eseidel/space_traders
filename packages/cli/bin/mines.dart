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
  final mineCountLimit = int.tryParse(argResults['limit'] as String);
  if (mineCountLimit == null) {
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

  final mines =
      await evaluateWaypointsForMining(waypointCache, marketCache, hqSystem);

  final table = Table(
    header: ['Mine', 'Traits', 'Market', 'Score'],
    style: const TableStyle(compact: true),
  );

  // Limit to only the closest for each.
  final seenMines = <WaypointSymbol>{};
  for (final mine in mines) {
    if (seenMines.contains(mine.mine)) {
      continue;
    }
    // Only consider markets that trade all goods produced by the mine.
    if (!mine.marketTradesAllProducedGoods) {
      logger
        ..warn('${mine.market} does not trade ${mine.goodsMissingFromMarket}'
            ' produced by ${mine.mine}')
        ..info('${mine.market} trades ${mine.tradedGoods}');
      continue;
    }
    seenMines.add(mine.mine);
    table.add([
      mine.mine.toString(),
      mine.mineTraitNames.join(', '),
      mine.market.toString(),
      mine.score,
    ]);
    if (seenMines.length >= mineCountLimit) {
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
