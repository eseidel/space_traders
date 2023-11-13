import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:cli_table/cli_table.dart';

Future<void> cliMain(FileSystem fs, ArgResults argResults) async {
  final shipType = shipTypeFromArg(argResults['ship'] as String);
  final limit = int.parse(argResults['limit'] as String);
  final startArg = argResults['start'] as String?;
  final credits = int.parse(argResults['credits'] as String);
  const maxWaypoints = 200;

  final staticCaches = StaticCaches.load(fs);
  final systemsCache = SystemsCache.load(fs)!;
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

  final constructionCache = ConstructionCache.load(fs);

  final start = startArg == null
      ? agentCache.headquarters(systemsCache)
      : systemsCache.waypointFromString(startArg)!;

  final jumpGate = systemsCache.jumpGateWaypointForSystem(start.systemSymbol)!;
  final construction =
      constructionCache.constructionForSymbol(jumpGate.waypointSymbol);
  centralCommand.setActiveConstruction(construction);
  extraSellOpps.addAll(centralCommand.constructionSellOpps());

  final ship = staticCaches.shipyardShips[shipType]!;
  final cargoCapacity = ship.cargoCapacity;
  final shipSpeed = ship.engine.speed;
  final fuelCapacity = ship.frame.fuelCapacity;

  logger.info('$shipType @ ${start.symbol}, '
      'speed = $shipSpeed '
      'capacity = $cargoCapacity, '
      'fuel <= $fuelCapacity, '
      'outlay <= $credits, '
      'waypoints <= $maxWaypoints ');

  if (extraSellOpps.isNotEmpty) {
    logger.info('Extra sell opps:');
    for (final extraOpp in extraSellOpps) {
      final type =
          extraOpp.isConstructionDelivery ? 'construction' : 'contract';
      logger.info('  $type: ${extraOpp.maxUnits} ${extraOpp.tradeSymbol} -> '
          '${extraOpp.waypointSymbol} @ ${creditsString(extraOpp.price)}');
    }
  }

  final marketScan = scanNearbyMarkets(
    systemsCache,
    marketPrices,
    systemSymbol: start.systemSymbol,
    maxWaypoints: maxWaypoints,
  );
  logger.info('Opps for ${marketScan.tradeSymbols.length} trade symbols.');
  final deals = findDealsFor(
    marketPrices,
    systemsCache,
    routePlanner,
    marketScan,
    maxTotalOutlay: credits,
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

  final table = Table(
    header: [
      'Symbol',
      'Start',
      'Buy',
      'End',
      'Sell',
      'Profit',
      'Gain',
      'Time',
      'c/s',
      'Outlay',
      'COGS',
      'OpEx',
    ],
    style: const TableStyle(compact: true),
  );

  final allSameSystem = deals.every(
    (deal) =>
        deal.deal.sourceSymbol.systemSymbol == start.systemSymbol &&
        deal.deal.destinationSymbol.systemSymbol == start.systemSymbol,
  );
  String w(WaypointSymbol symbol) =>
      allSameSystem ? symbol.waypointName : symbol.sectorLocalName;
  Map<String, dynamic> rightAlign(String content) => <String, dynamic>{
        'content': content,
        'hAlign': HorizontalAlign.right,
      };
  Map<String, dynamic> c(int credits) => rightAlign(creditsString(credits));
  for (final costed in deals.take(limit)) {
    final deal = costed.deal;
    final profit = costed.expectedProfit;
    final sign = profit > 0 ? '+' : '';
    final profitPercent = (profit / costed.expectedCosts) * 100;
    final tradeSymbol = deal.tradeSymbol.value;
    final name =
        costed.isContractDeal ? '$tradeSymbol (contract)' : tradeSymbol;

    table.add([
      name,
      w(deal.sourceSymbol),
      c(costed.expectedInitialBuyPrice),
      w(deal.destinationSymbol),
      c(costed.expectedInitialSellPrice),
      c(profit),
      rightAlign('$sign${profitPercent.toStringAsFixed(0)}%'),
      rightAlign(approximateDuration(costed.expectedTime)),
      rightAlign(costed.expectedProfitPerSecond.toString()),
      c(costed.expectedCosts),
      c(costed.expectedCostOfGoodsSold),
      c(costed.expectedOperationalExpenses),
    ]);
  }
  logger.info(table.toString());
}

void main(List<String> args) async {
  await runOffline(
    args,
    cliMain,
    addArgs: (ArgParser parser) {
      parser
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
          help: 'Ship type used for calculations',
          allowed: ShipType.values.map(argFromShipType),
          defaultsTo: argFromShipType(ShipType.LIGHT_HAULER),
        )
        ..addOption(
          'credits',
          abbr: 'c',
          help: 'Credit limit used for calculations',
          defaultsTo: '1000000',
        );
    },
  );
}
