import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final surveyData = await SurveyData.load(fs);
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
    marketPrices,
    surveyData,
    surveyWaypointSymbol: mineSymbol,
    nearbyMarketSymbol: mineSymbol,
  );
  logger.info('$survey');
}

void main(List<String> args) async {
  await runOffline(args, command);
}
