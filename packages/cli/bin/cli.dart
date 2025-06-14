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

bool Function(Ship ship)? _shipFilterFromArgs(Agent agent, List<String> only) {
  if (only.isEmpty) {
    return null;
  }
  final onlyShips = only.map(
    (s) => ShipSymbol(agent.symbol, int.parse(s, radix: 16)),
  );
  if (onlyShips.isNotEmpty) {
    logger.info('Only running ships: $onlyShips');
  }
  return (Ship ship) => onlyShips.contains(ship.symbol);
}

/// Similar to waitFor in idle_queue.dart.
Future<void> waitForSystem(Database db, GalaxyStats galaxy) async {
  while (true) {
    final systems = await db.systems.countSystemRecords();
    final waypoints = await db.systems.countSystemWaypoints();
    if (systems >= galaxy.systemCount && waypoints >= galaxy.waypointCount) {
      logger.info('Systems and waypoints are cached.');
      return;
    }
    logger.info(
      'Waiting for systems to be cached... '
      '$systems/${galaxy.systemCount} systems and '
      '$waypoints/${galaxy.waypointCount} waypoints.',
    );
    await Future<void>.delayed(const Duration(minutes: 1));
  }
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

  var agentSymbol = await db.config.getAgentSymbol();
  if (agentSymbol == null) {
    agentSymbol = Platform.environment['ST_AGENT'];
    if (agentSymbol != null) {
      logger.info('Using agent symbol from environment: $agentSymbol');
      await db.config.setAgentSymbol(agentSymbol);
    }
  }
  if (agentSymbol == null) {
    throw StateError('No agent symbol found in database or environment.');
  }
  final Api api;
  if (await db.config.getAuthToken() == null) {
    final email = Platform.environment['ST_EMAIL'];
    logger.info('No auth token found.');
    // Otherwise, register a new user.
    final token = await register(db, agentSymbol: agentSymbol, email: email);
    await db.config.setAuthToken(token);
    api = apiFromAuthToken(token, db);
  } else {
    api = await defaultApi(db);
  }

  if (results['selloff'] as bool) {
    logger.err('Selling all ships!');
    await db.config.setGamePhase(GamePhase.selloff);
  }

  logger.info('Playing as $agentSymbol');

  // First we ask the API how many systems there are.
  final galaxy = await getGalaxyStats(api);
  await waitForSystem(db, galaxy);

  config = await Config.fromDb(db);

  final caches = await Caches.loadOrFetch(api, db);
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
  final centralCommand = CentralCommand();

  final status = await api.defaultApi.getStatus();
  printStatus(status);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    final duration = DateTime.timestamp().difference(start);
    printRequestStats(api.requestCounts, duration);
    exit(0);
  });

  final agent = await fetchAndCacheMyAgent(db, api);
  final ships = await ShipSnapshot.load(db);
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info('Fleet: ${describeShips(ships.ships)}');

  // We use defaultTo: [], so we don't have to check fo null here.
  // This means that we won't notice `--only` being passed with no ships.
  // But that's also OK since that's nonsensical.
  final shipFilter = _shipFilterFromArgs(
    agent,
    results['only'] as List<String>,
  );
  await logic(api, db, centralCommand, caches, shipFilter: shipFilter);
}

Future<void> main(List<String> args) async {
  await runScoped(() async => await cliMain(args), values: {loggerRef});
}
