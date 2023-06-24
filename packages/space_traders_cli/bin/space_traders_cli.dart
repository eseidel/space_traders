import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/rate_limit.dart';
import 'package:space_traders_cli/printing.dart';

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
    '${caches.marketPrices.waypointCount} markets.',
  );
  final behaviorCache = await BehaviorCache.load(fs);
  final centralCommand = CentralCommand(behaviorCache);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    printRequestStats(api.apiClient);
    exit(0);
  });

  final agentCache = await AgentCache.load(api);
  final agent = agentCache.agent;
  logger.info(
    'Welcome ${agent.symbol} of the ${agent.startingFaction}!'
    ' ${creditsString(agent.credits)}',
  );
  final shipCache = await ShipCache.load(api);
  logger.info(describeFleet(shipCache));

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
