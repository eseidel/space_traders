import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/idle_queue.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = await defaultApi(db, getPriority: () => networkPriorityLow);

  var agentSymbol = await db.getAgentSymbol();
  while (agentSymbol == null) {
    logger.info('No agent symbol found in database, waiting 1 minute.');
    await Future<void>.delayed(const Duration(minutes: 1));
    agentSymbol = await db.getAgentSymbol();
  }

  var agent = await db.getAgent(symbol: agentSymbol);
  while (agent == null) {
    logger.info('Agent not yet found in database, waiting 1 minute.');
    await Future<void>.delayed(const Duration(minutes: 1));
    agent = await db.getAgent(symbol: agentSymbol);
  }

  final systemSymbol = agent.headquarters.system;
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
      WaypointCache(api, db, systems, charting, construction, waypointTraits);
  final marketCache = MarketCache(db, api, tradeGoods);
  final constructionCache = ConstructionCache(db);

  const printEvery = 100;
  var count = 0;
  resetQueue();

  if (argResults['all'] as bool) {
    final interestingSystems = findInterestingSystems(systems);
    for (final symbol in interestingSystems) {
      queue.queueSystem(symbol, jumpDistance: 0);
    }
  }

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
  await runOffline(
    args,
    command,
    addArgs: (parser) => parser.addFlag(
      'all',
      abbr: 'a',
      help: 'Seed queue with all starter systems.',
    ),
    loadConfig: false,
  );
}
