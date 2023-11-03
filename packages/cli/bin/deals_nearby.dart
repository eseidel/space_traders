import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';

Future<void> cliMain(FileSystem fs, ArgResults argResults) async {
  final maxJumps = int.parse(argResults['jumps'] as String);
  const shipType = ShipType.LIGHT_HAULER;
  final limit = int.parse(argResults['limit'] as String);

  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.loadCached(fs)!;
  final marketListings = MarketListingCache.load(fs, staticCaches.tradeGoods);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final marketPrices = MarketPrices.load(fs);

  final behaviorCache = BehaviorCache.load(fs);
  final shipCache = ShipCache.loadCached(fs)!;
  final agentCache = AgentCache.loadCached(fs)!;
  final contractCache = ContractCache.loadCached(fs)!;
  final centralCommand =
      CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);
  final extraSellOpps =
      centralCommand.contractSellOpps(agentCache, contractCache).toList();

  final start = argResults.rest.isEmpty
      ? agentCache.headquarters(systemsCache)
      : systemsCache.waypointFromString(argResults.rest.first)!;

  const maxWaypoints = 200;
  const maxOutlay = 1000000;
  final ship = staticCaches.shipyardShips[shipType]!;
  final cargoCapacity = ship.cargoCapacity;
  final shipSpeed = ship.engine.speed;
  final fuelCapacity = ship.frame.fuelCapacity;

  logger.info('$shipType @ ${start.symbol}, '
      'speed = $shipSpeed '
      'capacity = $cargoCapacity, '
      'fuel <= $fuelCapacity, '
      'outlay <= $maxOutlay, '
      'jumps <= $maxJumps, '
      'waypoints <= $maxWaypoints ');

  if (extraSellOpps.isNotEmpty) {
    logger.info('Contract opps:');
    for (final extraOpp in extraSellOpps) {
      logger.info('  ${extraOpp.maxUnits} ${extraOpp.tradeSymbol} -> '
          '${extraOpp.marketSymbol} @ ${creditsString(extraOpp.price)}');
    }
  }

  final marketScan = scanNearbyMarkets(
    systemsCache,
    marketPrices,
    systemSymbol: start.systemSymbol,
    maxJumps: maxJumps,
    maxWaypoints: maxWaypoints,
  );
  logger.info('Opps for ${marketScan.tradeSymbols.length} trade symbols.');
  final deals = findDealsFor(
    marketPrices,
    systemsCache,
    routePlanner,
    marketScan,
    maxTotalOutlay: maxOutlay,
    cargoCapacity: cargoCapacity,
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
    startSymbol: start.waypointSymbol,
    extraSellOpps: extraSellOpps,
  );

  if (deals.isEmpty) {
    logger.info('No deal found.');
    return;
  }
  logger.info('Top $limit deals:');
  for (final deal in deals.take(limit)) {
    logger.info(describeCostedDeal(deal));
  }
}

void main(List<String> args) async {
  await runOffline(
    args,
    cliMain,
    addArgs: (ArgParser parser) {
      parser
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
        ..addOption(
          'limit',
          abbr: 'l',
          help: 'Maximum number of deals to show',
          defaultsTo: '10',
        )
        ..addOption(
          'ship',
          abbr: 't',
          help: 'Ship type (defaults to ${ShipType.LIGHT_HAULER})',
          allowed: ShipType.values.map((e) => e.toString()).toList(),
          defaultsTo: ShipType.LIGHT_HAULER.toString(),
        );
    },
  );
}
