import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:cli/printing.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

void printRequestStats(RateLimitedApiClient client) {
  final counts = client.requestCounts.counts;
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
  logger.info('Total: ${client.requestCounts.totalRequests()} requests.');
}

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.');
  final results = parser.parse(args);

  logger.level = results['verbose'] as bool ? Level.verbose : Level.info;

  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();

  final env = Platform.environment;
  final callsign = env['SPACETRADERS_CALLSIGN'];
  final email = env['SPACETRADERS_EMAIL'];
  final token =
      await loadAuthTokenOrRegister(fs, callsign: callsign, email: email);
  final api = apiFromAuthToken(token);

  final caches = await Caches.load(fs, api);
  logger.info(
    'Loaded ${caches.marketPrices.count} prices from '
    '${caches.marketPrices.waypointCount} markets and '
    '${caches.shipyardPrices.count} prices from '
    '${caches.shipyardPrices.waypointCount} shipyards.',
  );
  final centralCommand =
      CentralCommand(behaviorCache: caches.behaviors, shipCache: caches.ships);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    printRequestStats(api.apiClient);
    exit(0);
  });

  final agent = caches.agent.agent;
  logger
    ..info(
      'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
      ' ${creditsString(agent.credits)}',
    )
    ..info(describeFleet(caches.ships));

  await logic(api, centralCommand, caches);
}

Future<void> main(List<String> args) async {
  await runScoped(
    () async {
      await cliMain(args);
    },
    values: {loggerRef},
  );
}
