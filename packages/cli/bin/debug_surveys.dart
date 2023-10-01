import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final marketPrices = MarketPrices.load(fs);
  final agentCache = AgentCache.loadCached(fs)!;
  final systemsCache = await SystemsCache.load(fs);

  final hq = agentCache.agent.headquartersSymbol;
  final hqSystemSymbol = hq.systemSymbol;
  final systemSymbol = hqSystemSymbol;

  final systemWaypoints = systemsCache.waypointsInSystem(systemSymbol);
  final mineSymbol =
      systemWaypoints.firstWhere((w) => w.canBeMined).waypointSymbol;

  final survey = await surveyWorthMining(
    db,
    marketPrices,
    surveyWaypointSymbol: mineSymbol,
    nearbyMarketSymbol: mineSymbol,
  );
  logger.info('$survey');
  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
