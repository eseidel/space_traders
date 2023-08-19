import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final db = await defaultDatabase();
  final marketPrices = MarketPrices.load(fs);
  final systemsCache = await SystemsCache.load(fs);

  final agent = await db.myCachedAgent();
  final hq = agent!.headquartersSymbol;
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
