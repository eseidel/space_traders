import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/logic.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/register.dart';
import 'package:db/db.dart';
import 'package:scoped_deps/scoped_deps.dart';
import 'package:types/types.dart';

void printRequestStats(RequestCounts requestCounts, Duration duration) {
  final counts = requestCounts.counts;
  final generalizedCounts = <String, int>{};
  for (final key in counts.keys) {
    final generalizedKey = key
        .split('/')
        .map((part) => part.contains('-') ? 'N' : part)
        .join('/');
    generalizedCounts[generalizedKey] =
        (generalizedCounts[generalizedKey] ?? 0) + counts[key]!;
  }
  // print the counts in order of most to least.
  final sortedCounts = generalizedCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  logger.info('Request stats:');
  for (final entry in sortedCounts) {
    logger.info('${entry.value} ${entry.key}');
  }
  final possible = (duration.inSeconds * networkConfig.targetRequestsPerSecond)
      .round();
  final percent = requestCounts.total / possible;
  final percentString = '${(percent * 100).round()}%';
  final avg = requestCounts.total / duration.inSeconds;
  logger
    ..info(
      'Total: ${requestCounts.total} requests '
      'over ${approximateDuration(duration)}. '
      '(avg ${avg.toStringAsFixed(2)} r/s)',
    )
    ..info('Used $percentString of $possible possible requests.');
}

/// Print the status of the server.
void printStatus(GetStatus200Response s) {
  final mostCreditsString = s.leaderboards.mostCredits
      .map(
        (e) =>
            '${e.agentSymbol.padLeft(14)} '
            '${creditsString(e.credits).padLeft(14)}',
      )
      .join(', ');
  final mostChartsString = s.leaderboards.mostSubmittedCharts
      .map(
        (e) =>
            '${e.agentSymbol.padLeft(14)} '
            '${e.chartCount.toString().padLeft(14)}',
      )
      .join(', ');
  final now = DateTime.timestamp();
  final resetDate = DateTime.tryParse(s.resetDate)!;
  final sinceLastReset = approximateDuration(now.difference(resetDate));
  final nextResetDate = DateTime.tryParse(s.serverResets.next)!;
  final untilNextReset = approximateDuration(nextResetDate.difference(now));
  final statsParts = [
    '${s.stats.agents} agents',
    '${s.stats.ships} ships',
    '${s.stats.systems} systems',
    '${s.stats.waypoints} waypoints',
  ].map((e) => e.padLeft(20)).toList();

  logger
    ..info('Stats: ${statsParts.join(' ')}')
    ..info('Most Credits: $mostCreditsString')
    ..info('Most Charts:  $mostChartsString')
    ..info(
      'Last reset $sinceLastReset ago, '
      'next reset: $untilNextReset, '
      'cadence: ${s.serverResets.frequency}',
    );
  final knownAnnouncementTitles = ['Server Resets', 'Discord', 'Support Us'];
  for (final announcement in s.announcements) {
    if (knownAnnouncementTitles.contains(announcement.title)) {
      continue;
    }
    logger.info('Announcement: ${announcement.title}');
  }
}

/// Similar to waitFor in idle_queue.dart.
Future<void> waitForSystem(Database db, GalaxyStats galaxy) async {
  while (true) {
    final systems = await db.systems.countSystemRecords();
    final waypoints = await db.systems.countSystemWaypoints();
    if (systems >= galaxy.systemCount && waypoints >= galaxy.waypointCount) {
      logger.info('$systems systems and $waypoints waypoints are cached.');
      return;
    }
    logger.info(
      'Waiting for systems and waypoints to be cached... '
      '$systems/${galaxy.systemCount} systems and '
      '$waypoints/${galaxy.waypointCount} waypoints.',
    );
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}

Future<String> getAgentToken(Database db, {required Uri baseUri}) async {
  final agentToken = await db.config.getAgentToken();
  final accountToken = await db.global.getAccountToken();
  if (agentToken == null && accountToken == null) {
    throw StateError('No agent or account token found.');
  }
  // First check if we have an agent token
  if (agentToken != null) {
    // The token might be invalid, but further callers will handle that.
    return agentToken;
  }

  final agentSymbolFromEnv = Platform.environment['ST_AGENT'];
  if (agentSymbolFromEnv == null) {
    throw StateError('No agent symbol found, cannot register new agent.');
  }
  // Otherwise, register a new user.
  final token = await register(
    db,
    agentSymbol: agentSymbolFromEnv,
    baseUri: baseUri,
  );
  await db.config.setAgentToken(token);
  return token;
}

Future<Api> getApi(Database db, {required Uri baseUri}) async {
  final agentToken = await getAgentToken(db, baseUri: baseUri);
  return apiFromAuthToken(agentToken, db, baseUri: baseUri);
}

Future<void> printDbStats(Database db) async {
  final marketPricesCount = await db.marketPrices.count();
  final marketWaypointsCount = await db.marketPrices.countWaypoints();
  final shipyardPricesCount = await db.shipyardPrices.count();
  final shipyardWaypointsCount = await db.shipyardPrices.waypointCount();
  logger.info(
    'Loaded $marketPricesCount prices from '
    '$marketWaypointsCount markets and '
    '$shipyardPricesCount prices from '
    '$shipyardWaypointsCount shipyards.',
  );
}

Future<void> enterReset(Api api, Database db, Uri baseUri) async {
  final myAgent = await api.agents.getMyAgent();
  final agentSymbol = myAgent.data.symbol;
  logger.info('Playing as $agentSymbol on $baseUri');

  // First we ask the API how many systems there are.
  final galaxy = await getGalaxyStats(api);
  // Wait for starting system to be cached if necessary.
  await waitForSystem(db, galaxy);

  // Print the leaderboards.
  final status = await api.defaultApi.getStatus();
  printStatus(status);

  await printDbStats(db);

  config = await Config.fromDb(db);
  final caches = await Caches.loadOrFetch(api, db);
  final centralCommand = CentralCommand();

  final agent = await fetchAndCacheMyAgent(db, api);
  final ships = await ShipSnapshot.load(db);
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info('Fleet: ${describeShips(ships.ships)}');

  await logic(api, db, centralCommand, caches);
}

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.')
    ..addFlag('selloff', negatable: false, help: 'Sell off ships.')
    ..addMultiOption(
      'only',
      abbr: 'o',
      help: 'Only run the given ship numbers (hex).',
    );
  final results = parser.parse(args);

  logger.level = results['verbose'] as bool ? Level.verbose : Level.info;

  final start = DateTime.timestamp();

  logger.info('Welcome to Space Traders! 🚀');

  final db = await defaultDatabase();
  final baseUri = await determineBaseUri(db);
  final api = await getApi(db, baseUri: baseUri);
  // Handle ctrl-c and print out request stats.
  ProcessSignal.sigint.watch().listen((signal) {
    final duration = DateTime.timestamp().difference(start);
    printRequestStats(api.requestCounts, duration);
    exit(0);
  });

  await enterReset(api, db, baseUri);
}

Future<void> main(List<String> args) async {
  await runScoped(() async => await cliMain(args), values: {loggerRef});
}
