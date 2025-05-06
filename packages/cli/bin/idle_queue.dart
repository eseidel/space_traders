import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/idle_queue.dart';
import 'package:cli/logic/systems_fetcher.dart';
import 'package:cli/net/auth.dart';

Future<T> waitFor<T>(Database db, Future<T?> Function() get) async {
  var value = await get();
  while (value == null) {
    logger.info('$T not yet in database, waiting 1 minute.');
    await Future<void>.delayed(const Duration(minutes: 1));
    value = await get();
  }
  return value;
}

Future<void> command(Database db, ArgResults argResults) async {
  final api = await waitForApi(db, getPriority: () => networkPriorityLow);
  final agent = await waitFor(db, () => db.getMyAgent());

  /// Make sure we've cached all systems and waypoints before bothering to
  /// start the idle queue.
  final systemsFetcher = SystemsFetcher(db, api);
  await systemsFetcher.ensureAllSystemsCached();

  final systemSymbol = agent.headquarters.system;
  var queue = IdleQueue();
  void resetQueue() {
    queue = IdleQueue()..queueSystem(systemSymbol, jumpDistance: 0);
  }

  final tradeGoods = TradeGoodCache(db);
  final waypointCache = WaypointCache(api, db);
  final marketCache = MarketCache(db, api, tradeGoods);
  final constructionCache = ConstructionCache(db);

  const printEvery = 100;
  var count = 0;
  resetQueue();

  if (argResults['all'] as bool) {
    final interestingSystems = findInterestingSystems(
      await db.systems.snapshotAllSystems(),
    );
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

    await queue.runOne(db, api, waypointCache, marketCache, constructionCache);
  }
}

void main(List<String> args) async {
  await runOffline(
    args,
    command,
    addArgs:
        (parser) => parser.addFlag(
          'all',
          abbr: 'a',
          help: 'Seed queue with all starter systems.',
        ),
    loadConfig: false,
  );
}
