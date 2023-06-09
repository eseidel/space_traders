import 'package:args/args.dart';
import 'package:collection/collection.dart';
import 'package:file/local.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/systems_cache.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '0',
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
  final systemsCache = await SystemsCache.load(fs);
  final waypointCache = WaypointCache(api, systemsCache);

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

  final marketCache = MarketCache(waypointCache);
  final priceData = await PriceData.load(fs);
  final markets = await systemSymbolsInJumpRadius(
    waypointCache: waypointCache,
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )
      .asyncExpand(
        (record) => marketCache.marketsInSystem(record.$1),
      )
      .toList();
  final finder = DealFinder(priceData);
  for (final market in markets) {
    finder.visitMarket(market);
  }
  final deals = finder.findDeals();

  final sortedDeals = deals.sorted((a, b) => a.profit.compareTo(b.profit));
  if (sortedDeals.isEmpty) {
    logger.info('No deals found.');
    return;
  }
  logDeals(sortedDeals);
}
