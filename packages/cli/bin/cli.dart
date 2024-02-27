import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/counts.dart';
import 'package:cli/net/register.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:types/types.dart';

void printRequestStats(RequestCounts requestCounts, Duration duration) {
  final counts = requestCounts.counts;
  final generalizedCounts = <String, int>{};
  for (final key in counts.keys) {
    final generalizedKey =
        key.split('/').map((part) => part.contains('-') ? 'N' : part).join('/');
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
  final possible =
      (duration.inSeconds * config.targetRequestsPerSecond).round();
  final percent = requestCounts.totalRequests / possible;
  final percentString = '${(percent * 100).round()}%';
  final avg = requestCounts.totalRequests / duration.inSeconds;
  logger
    ..info('Total: ${requestCounts.totalRequests} requests '
        'over ${approximateDuration(duration)}. '
        '(avg ${avg.toStringAsFixed(2)} r/s)')
    ..info('Used $percentString of $possible possible requests.');
}

/// Print the status of the server.
void printStatus(GetStatus200Response s) {
  final mostCreditsString = s.leaderboards.mostCredits
      .map(
        (e) => '${e.agentSymbol.padLeft(14)} '
            '${creditsString(e.credits).padLeft(14)}',
      )
      .join(', ');
  final mostChartsString = s.leaderboards.mostSubmittedCharts
      .map(
        (e) => '${e.agentSymbol.padLeft(14)} '
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
    ..info(
      'Stats: ${statsParts.join(' ')}',
    )
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
  final onlyShips =
      only.map((s) => ShipSymbol(agent.symbol, int.parse(s, radix: 16)));
  if (onlyShips.isNotEmpty) {
    logger.info('Only running ships: $onlyShips');
  }
  return (Ship ship) => onlyShips.contains(ship.shipSymbol);
}

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.')
    ..addMultiOption(
      'only',
      abbr: 'o',
      help: 'Only run the given ship numbers (hex).',
    );
  final results = parser.parse(args);

  logger.level = results['verbose'] as bool ? Level.verbose : Level.info;

  final start = DateTime.timestamp();

  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();
  final db = await defaultDatabase();
  final token = await loadAuthTokenOrRegister(fs, db);

  // Api client should move to per-ship with a per-ship priority function.
  final api = apiFromAuthToken(token, db);

  final caches = await Caches.loadOrFetch(fs, api, db);
  final marketPricesCount = await db.marketPricesCount();
  final marketWaypointsCount = await db.marketPricesWaypointCount();
  final shipyardPricesCount = await db.shipyardPricesCount();
  final shipyardWaypointsCount = await db.shipyardPricesWaypointCount();
  logger.info(
    'Loaded $marketPricesCount prices from '
    '$marketWaypointsCount markets and '
    '$shipyardPricesCount prices from '
    '$shipyardWaypointsCount shipyards.',
  );
  final centralCommand = CentralCommand(shipCache: caches.ships);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    final duration = DateTime.timestamp().difference(start);
    printRequestStats(api.requestCounts, duration);
    exit(0);
  });

  final agent = caches.agent.agent;
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info('Fleet: ${describeShips(caches.ships.ships)}');

  // We use defaultTo: [], so we don't have to check fo null here.
  // This means that we won't notice `--only` being passed with no ships.
  // But that's also OK since that's nonsentical.
  final shipFilter =
      _shipFilterFromArgs(agent, results['only'] as List<String>);
  await logic(api, db, centralCommand, caches, shipFilter: shipFilter);
}

Future<void> main(List<String> args) async {
  await runScoped(
    () async {
      await cliMain(args);
    },
    values: {loggerRef},
  );
}
