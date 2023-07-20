import 'package:args/args.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
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
  // final maxJumps = int.parse(results['jumps'] as String);
  if (results['verbose'] as bool) {
    setVerboseLogging();
  }

  const fs = LocalFileSystem();
  final systemsCache = SystemsCache.loadCached(fs)!;
  final routePlanner = RoutePlanner.fromSystemsCache(systemsCache);

  final marketPrices = MarketPrices.load(fs);

  final behaviorCache = BehaviorCache.load(fs);
  final shipCache = ShipCache.loadCached(fs)!;
  final agentCache = AgentCache.loadCached(fs)!;
  final contractCache = ContractCache.loadCached(fs)!;
  final centralCommand =
      CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
  final extraSellOpps =
      centralCommand.contractSellOpps(agentCache, contractCache).toList();

  for (final extraOpp in extraSellOpps) {
    logger.info('Extra: ${extraOpp.tradeSymbol} ${extraOpp.maxUnits} '
        '${extraOpp.price} => ${extraOpp.marketSymbol}');
  }

  // const maxWaypoints = 100;
  // const maxOutlay = 100000;
  // const cargoCapacity = 120;
  // const shipSpeed = 30;
  // const fuelCapacity = 1200;
  // final agentCache = AgentCache.loadCached(fs)!;
  final start = results.rest.isEmpty
      ? agentCache.headquarters(systemsCache)
      : systemsCache.waypointFromSymbol(results.rest.first);

  // Finding deals with start: X1-SB93-93497E, max jumps: 5,
  // max outlay: 1172797, max units: 120, fuel capacity: 1700, ship speed: 10
  const maxJumps = 10;
  const maxWaypoints = 200;
  const maxOutlay = 1172797;
  const cargoCapacity = 120;
  const shipSpeed = 10;
  const fuelCapacity = 1700;
  // final start = systemsCache.waypointFromSymbol('X1-SB93-93497E');

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

  final marketScan = scanNearbyMarkets(
    systemsCache,
    marketPrices,
    systemSymbol: start.systemSymbol.system,
    maxJumps: maxJumps,
    maxWaypoints: maxWaypoints,
  );
  logger
      .info('Found opps for ${marketScan.tradeSymbols.length} trade symbols.');
  final maybeDeal = await findDealFor(
    marketPrices,
    systemsCache,
    routePlanner,
    marketScan,
    maxJumps: maxJumps,
    maxTotalOutlay: maxOutlay,
    cargoCapacity: cargoCapacity,
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    startSymbol: start.symbol,
    extraSellOpps: extraSellOpps,
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
