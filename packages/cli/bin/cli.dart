import 'dart:io';

import 'package:args/args.dart';
import 'package:cli/api.dart';
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
  final agentSymbol = Platform.environment['ST_AGENT'];

  final db = await defaultDatabase();
  final baseUri = await determineBaseUri(db);
  // Explicitly get an apiClient so we have it typed as AuthorizedClient.
  final apiClient = await getApiClient(db, baseUri: baseUri);
  apiClient
    ..accountToken = await db.global.getAccountToken()
    // accountToken must be set first since registerAgentIfNeeded might call
    // register which would use the accountToken.
    ..agentToken = await registerAgentIfNeeded(
      db,
      baseUri: baseUri,
      agentSymbol: agentSymbol,
    );

  final api = Api(apiClient);

  // Handle ctrl-c and print out request stats.
  ProcessSignal.sigint.watch().listen((signal) {
    final duration = DateTime.timestamp().difference(start);
    printRequestStats(api.requestCounts, duration);
    exit(0);
  });
  await reregisterLoop(api, db, baseUri, agentSymbol: agentSymbol);
}

Future<void> main(List<String> args) async {
  await runScoped(() async => await cliMain(args), values: {loggerRef});
}
