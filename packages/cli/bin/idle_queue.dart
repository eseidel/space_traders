import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/idle_queue.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final agent = await db.getAgent(symbol: config.agentSymbol);
  final systemSymbol = agent!.headquarters.system;
  var queue = IdleQueue();
  void resetQueue() {
    queue = IdleQueue()..queueSystem(systemSymbol, jumpDistance: 0);
  }

  final systems = await SystemsCache.loadOrFetch(fs);
  final charting = ChartingCache(db);
  final construction = ConstructionCache(db);
  final waypointTraits = WaypointTraitCache.load(fs);
  final tradeGoods = TradeGoodCache.load(fs);
  final waypointCache =
      WaypointCache(api, systems, charting, construction, waypointTraits);
  final marketCache = MarketCache(db, api, tradeGoods);
  final constructionCache = ConstructionCache(db);

  const printEvery = 100;
  var count = 0;
  resetQueue();
  while (true) {
    if (queue.isDone) {
      logger.info('Queue is done, waiting 1 minute.');
      await Future<void>.delayed(const Duration(minutes: 1));
      resetQueue();
    }

    if (count++ % printEvery == 0) {
      logger.info('$queue');
    }

    await queue.runOne(
      db,
      api,
      systems,
      waypointCache,
      marketCache,
      constructionCache,
    );
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
