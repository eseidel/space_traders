import 'package:args/args.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/trading.dart';
import 'package:file/local.dart';
import 'package:scoped/scoped.dart';

Future<void> cliMain(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'jumps',
      abbr: 'j',
      help: 'Maximum number of jumps to walk out',
      defaultsTo: '5',
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
  final systemsCache = SystemsCache.loadFromCache(fs)!;
  final agentCache = AgentCache.loadCached(fs)!;
  final systemConnectivity = SystemConnectivity.fromSystemsCache(systemsCache);

  final marketPrices = await MarketPrices.load(fs);
  // final waypointCache = WaypointCache(api, systemsCache);
  // final marketCache = MarketCache(waypointCache);
  // final marketScan = await scanMarketsNear(
  //   marketCache,
  //   marketPrices,
  //   systemSymbol: ship.nav.systemSymbol,
  //   maxJumps: maxJumps,
  // );

  const maxWaypoints = 100;
  const maxOutlay = 100000;
  const cargoCapacity = 120;
  const shipSpeed = 30;
  const fuelCapacity = 1200;
  final start = agentCache.headquarters(systemsCache);
  logger.info(
    'Finding deals with '
    'start: ${start.symbol}, '
    'max jumps: $maxJumps, '
    'max waypoints: $maxWaypoints, '
    'max outlay: $maxOutlay, '
    'max units: $cargoCapacity, '
    'fuel capacity: $fuelCapacity, '
    'ship speed: $shipSpeed',
  );

  final allowedWaypoints = systemsCache
      .waypointSymbolsInJumpRadius(
        startSystem: start.systemSymbol,
        maxJumps: maxJumps,
      )
      .take(maxWaypoints)
      .toSet();
  logger.info('Considering ${allowedWaypoints.length} waypoints');

  final marketScan = MarketScan.fromMarketPrices(
    marketPrices,
    waypointFilter: allowedWaypoints.contains,
  );
  final maybeDeal = await findDealFor(
    marketPrices,
    systemsCache,
    systemConnectivity,
    marketScan,
    maxJumps: maxJumps,
    maxTotalOutlay: maxOutlay,
    cargoCapacity: cargoCapacity,
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    startSymbol: start.symbol,
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
