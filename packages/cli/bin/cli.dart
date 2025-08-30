import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/logic.dart';
import 'package:cli/net/auth.dart';
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
