import 'dart:io';

import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/surveys.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/logic.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/rate_limit.dart';
import 'package:space_traders_cli/printing.dart';

// Consider having a config file like:
// https://gist.github.com/whyando/fed97534173437d8234be10ac03595e0
// instead of having this dynamic behavior function.
// At the top of the file because I change this so often.
Behavior _behaviorFor(
  BehaviorManager behaviorManager,
  Ship ship,
) {
  final disableBehaviors = <Behavior>[
    // Behavior.buyShip,
    // Behavior.contractTrader,
    Behavior.arbitrageTrader,
    // Behavior.miner,
    // Behavior.idle,
    // Behavior.explorer,
  ];

  final behaviors = {
    ShipRole.COMMAND: [
      Behavior.buyShip,
      Behavior.contractTrader,
      Behavior.arbitrageTrader,
      Behavior.miner
    ],
    // Can't have more than one contract trader on small/expensive contracts
    // or we'll overbuy.
    ShipRole.HAULER: [Behavior.contractTrader],
    ShipRole.EXCAVATOR: [Behavior.miner],
    ShipRole.SATELLITE: [Behavior.explorer],
  }[ship.registration.role];
  if (behaviors != null) {
    for (final behavior in behaviors) {
      if (disableBehaviors.contains(behavior)) {
        continue;
      }
      if (behaviorManager.isEnabled(behavior)) {
        return behavior;
      }
    }
  } else {
    logger
        .warn('${ship.registration.role} has no specified behaviors, idling.');
  }
  return Behavior.idle;
}

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

  final env = Platform.environment;
  final callsign = env['SPACETRADERS_CALLSIGN'];
  final email = env['SPACETRADERS_EMAIL'];
  final token =
      await loadAuthTokenOrRegister(fs, callsign: callsign, email: email);
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

  // Behaviors are expected to "complete" behaviors when done and
  // disable behaviors on error.
  final behaviorManager = await BehaviorManager.load(db, (bm, ship) {
    // TODO(eseidel): This logic is triggered twice for each ship?
    final behavior = _behaviorFor(bm, ship);
    // shipInfo(ship, 'Chose new behavior: $behavior');
    return behavior;
  });

  final status = await api.defaultApi.getStatus();
  printStatus(status!);

  // Handle ctrl-c and print out request stats.
  // This should be made an argument rather than on by default.
  ProcessSignal.sigint.watch().listen((signal) {
    final client = api.apiClient as RateLimitedApiClient;
    final counts = client.requestCounts.counts;
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
    behaviorManager,
  );
}
