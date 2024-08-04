import 'dart:io';

import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/logic/idle_queue.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final agent = await db.getAgent(symbol: config.agentSymbol);
  if (agent == null) {
    logger.err('Failed to load agent: ${config.agentSymbol}');
    exit(1);
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
  );
}
