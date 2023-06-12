import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/rate_limit.dart';
import 'package:space_traders_cli/shipyard_prices.dart';
import 'package:space_traders_cli/surveys.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/transactions.dart';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('verbose', abbr: 'v', negatable: false, help: 'Verbose logging.')
    ..addFlag(
      'update-prices',
      help: 'Force update of prices from server.',
    );
  final results = parser.parse(args);

  logger =
      Logger(level: results['verbose'] as bool ? Level.verbose : Level.info);

  logger.info('Welcome to Space Traders! 🚀');
  // Use package:file to make things mockable.
  const fs = LocalFileSystem();

  final token = await loadAuthTokenOrRegister(fs);
  final api = apiFromAuthToken(token);
  final db = DataStore();
  await db.open();

  final priceData = await PriceData.load(
    fs,
    updateFromServer: results['update-prices'] as bool,
  );
  final surveyData = await SurveyData.load(fs);
  logger.info(
    'Loaded ${priceData.count} prices from '
    '${priceData.waypointCount} waypoints.',
  );

  final systemsCache = await SystemsCache.load(fs);
  final transactions = await TransactionLog.load(fs);
  final shipyardPrices = await ShipyardPrices.load(fs);

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    final client = api.apiClient as RateLimitedApiClient;
    final counts = client.requestCounts.counts;
    // print the counts in order of most to least.
    final sortedCounts = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    logger.info('Request stats:');
    for (final entry in sortedCounts) {
      logger.info('${entry.value} ${entry.key}');
    }
    logger.info('Total: ${client.requestCounts.totalRequests()} requests.');
    exit(0);
  });

  await logic(
    api,
    db,
    systemsCache,
    priceData,
    shipyardPrices,
    surveyData,
    transactions,
  );
}
