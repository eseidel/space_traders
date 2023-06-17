import 'package:args/args.dart';
import 'package:file/local.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/auth.dart';
import 'package:space_traders_cli/net/queries.dart';
import 'package:space_traders_cli/trading.dart';

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
  final priceData = await PriceData.load(fs);
  final maybeDeal = await findDealFor(
    priceData,
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
