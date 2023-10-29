import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli_table/cli_table.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => 0);
  final systems = await SystemsCache.load(fs);
  final charting = ChartingCache.load(fs);
  final construction = ConstructionCache.load(fs);
  final waypointCache = WaypointCache(api, systems, charting, construction);
  final agentCache = AgentCache.loadCached(fs)!;
  final hqSystem = agentCache.agent.headquartersSymbol.systemSymbol;

  final mines = await evaluateWaypointsForMining(waypointCache, hqSystem);

  final table = Table(
    header: ['Mine', 'Traits', 'Market', 'Score'],
    style: const TableStyle(compact: true),
  );

  // Limit to only the closest for each (eventually this should use
  // information about what the mine produces and the market buys).
  final seenMines = <WaypointSymbol>{};
  for (final mine in mines) {
    if (seenMines.contains(mine.mine)) {
      continue;
    }
    seenMines.add(mine.mine);
    table.add([
      mine.mine.toString(),
      mine.mineTraitNames.join(', '),
      mine.market.toString(),
      mine.score,
    ]);
  }
  logger.info(table.toString());

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
