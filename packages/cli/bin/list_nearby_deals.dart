import 'package:args/args.dart';
import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/trading.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '1',
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
  final systemsCache = await SystemsCache.load(fs);
  final shipCache = ShipCache.loadCached(fs)!;
  // Just grab the command ship.
  final ship = shipCache.ships.first;

  final marketPrices = await MarketPrices.load(fs);
  // final waypointCache = WaypointCache(api, systemsCache);
  // final marketCache = MarketCache(waypointCache);
  // final marketScan = await scanMarketsNear(
  //   marketCache,
  //   marketPrices,
  //   systemSymbol: ship.nav.systemSymbol,
  //   maxJumps: maxJumps,
  // );
  logger.info('starting scan');
  final allowedWaypoints = systemsCache
      .waypointSymbolsInJumpRadius(
        startSystem: ship.nav.systemSymbol,
        maxJumps: maxJumps,
      )
      .toSet();
  logger.info('${allowedWaypoints.length} allowed waypoints');

  final marketScan = MarketScan.fromMarketPrices(
    marketPrices,
    waypointFilter: allowedWaypoints.contains,
  );
  logger.info('scan complete');
  final maybeDeal = await findDealFor(
    marketPrices,
    systemsCache,
    marketScan,
    ship,
    maxJumps: maxJumps,
    maxTotalOutlay: 10000,
    availableSpace: ship.availableSpace,
  );

  if (maybeDeal == null) {
    logger.info('No deal found.');
    return;
  }
  logger.info(describeCostedDeal(maybeDeal));
}

void main(List<String> args) async {
  await runScoped(() => cliMain(args), values: {loggerRef});
}
