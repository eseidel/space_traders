import 'package:args/args.dart';
import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/trading.dart';
import 'package:file/local.dart';

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

  final ships = allMyShips(api);
  final ship = await ships.first; // command ship

  final marketCache = MarketCache(waypointCache);
  final marketPrices = await MarketPrices.load(fs);
  final maybeDeal = await findDealFor(
    marketPrices,
    systemsCache,
    waypointCache,
    marketCache,
    ship,
    maxJumps: maxJumps,
    maxOutlay: 10000,
    availableSpace: ship.availableSpace,
  );

  if (maybeDeal == null) {
    logger.info('No deal found.');
    return;
  }
  logger.info(describeCostedDeal(maybeDeal));
}
