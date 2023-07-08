// Walk a list of nearby systems, looking for ones which have something
// mineable and a marketplace (ideally at the same location).
// Optionally also a shipyard.

import 'package:args/args.dart';
import 'package:cli/api.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '10',
    )
    ..addOption(
      'start',
      abbr: 's',
      help: 'Starting system (defaults to agent headquarters)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Verbose logging',
      negatable: false,
    );
  final results = parser.parse(args);
  final maxJumps = int.parse(results['jumps'] as String);
  if (results['verbose'] as bool) {
    setVerboseLogging();
  }

  const fs = LocalFileSystem();
  final api = defaultApi(fs);
  final systemsCache = SystemsCache.loadFromCache(fs)!;
  final waypointCache = WaypointCache(api, systemsCache);
  final marketCache = MarketCache(waypointCache);
  final marketPrices = await MarketPrices.load(fs);

  Waypoint start;
  final startArg = results['start'] as String?;
  if (startArg != null) {
    final maybeStart = await waypointCache.waypointOrNull(startArg);
    if (maybeStart == null) {
      logger.err('--start was invalid, unknown system: ${results['start']}');
      return;
    }
    start = maybeStart;
  } else {
    start = await waypointCache.getAgentHeadquarters();
  }

  final mine = await nearestMineWithGoodMining(
    api,
    marketPrices,
    systemsCache,
    waypointCache,
    marketCache,
    start,
    maxJumps: maxJumps,
    tradeSymbol: 'PRECIOUS_STONES',
  );
  if (mine == null) {
    logger.err('No good mining systems found.');
    return;
  }
  logger.info('Nearest good mine: $mine');
}

void main(List<String> args) async {
  await runScoped(() => cliMain(args), values: {loggerRef});
}
