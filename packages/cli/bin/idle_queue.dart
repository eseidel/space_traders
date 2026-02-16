import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/logic/idle_queue.dart';
import 'package:cli/logic/systems_fetcher.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';

/// Waits for the auth token to be available and then creates an API.
Future<Api> waitForApi(
  Database db, {
  required Uri baseUri,
  int Function() getPriority = defaultGetPriority,
}) async {
  final token = await waitFor(db, db.config.getAgentToken, name: 'agent token');
  return await apiFromAgentToken(
    token,
    db,
    baseUri: baseUri,
    getPriority: getPriority,
  );
}

Future<void> command(Database db, ArgResults argResults) async {
  final baseUri = await determineBaseUri(db);
  logger.info('Running idle queue for $baseUri');
  final api = await waitForApi(
    db,
    getPriority: () => networkPriorityLow,
    baseUri: baseUri,
  );
  final agent = await getMyAgent(api);
  logger.info('with ${agent.symbol}');

  /// Make sure we've cached all systems and waypoints before bothering to
  /// start the idle queue.
  final systemsFetcher = SystemsFetcher(db, api);
  await systemsFetcher.ensureAllSystemsCached();

  final systemSymbol = agent.headquarters.system;
  var queue = IdleQueue();
  void resetQueue() {
    queue = IdleQueue()..queueSystem(systemSymbol, jumpDistance: 0);
  }

  final waypointCache = WaypointCache(api, db);
  final marketCache = MarketCache(db, api);

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

    await queue.runOne(db, api, waypointCache, marketCache);
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
