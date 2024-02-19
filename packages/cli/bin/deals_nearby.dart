import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:cli_table/cli_table.dart';

Future<void> cliMain(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final shipType = shipTypeFromArg(argResults['ship'] as String);
  final limit = int.parse(argResults['limit'] as String);
  final startArg = argResults['start'] as String?;
  final credits = int.parse(argResults['credits'] as String);

  final systemsCache = SystemsCache.load(fs)!;
  final marketListings = await MarketListingSnapshot.load(db);
  final jumpGates = await JumpGateSnapshot.load(db);
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  // Can't use loadSystemConnectivity because need constructionSnapshot later.
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGates, constructionSnapshot);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systemsCache,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final marketPrices = await MarketPrices.load(db);

  final behaviorCache = await BehaviorCache.load(db);
  final shipCache = await ShipSnapshot.load(db);
  final agentCache = await AgentCache.load(db);
  final contractSnapshot = await ContractSnapshot.load(db);
  final centralCommand =
      CentralCommand(behaviorCache: behaviorCache, shipCache: shipCache);

  final start = startArg == null
      ? agentCache!.headquarters(systemsCache)
      : systemsCache.waypointFromString(startArg)!;

  final jumpGate = systemsCache.jumpGateWaypointForSystem(start.system)!;
  final construction = constructionSnapshot[jumpGate.symbol];
  centralCommand.activeConstruction = construction;

  final exportCache = TradeExportCache.load(fs);

  if (construction != null) {
    centralCommand.subsidizedSellOpps = computeConstructionMaterialSubsidies(
      marketListings,
      marketPrices,
      exportCache,
      construction,
    );
  }

  final extraSellOpps = <SellOpp>[];
  if (centralCommand.isContractTradingEnabled) {
    extraSellOpps
        .addAll(centralCommand.contractSellOpps(agentCache!, contractSnapshot));
  }
  if (centralCommand.isConstructionTradingEnabled) {
    extraSellOpps.addAll(centralCommand.constructionSellOpps());
  }

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final cargoCapacity = ship.cargoCapacity;
  final shipSpeed = ship.engine.speed;
  final fuelCapacity = ship.frame.fuelCapacity;

  logger.info('$shipType @ ${start.symbol}, '
      'speed = $shipSpeed '
      'capacity = $cargoCapacity, '
      'fuel <= $fuelCapacity, '
      'outlay <= $credits');

  if (extraSellOpps.isNotEmpty) {
    logger.info('Extra sell opps:');
    for (final extraOpp in extraSellOpps) {
      final String type;
      if (extraOpp.isConstructionDelivery) {
        type = 'construction';
      } else if (extraOpp.isContractDelivery) {
        type = 'contract';
      } else {
        type = 'subsidy';
      }
      logger.info('  $type: ${extraOpp.maxUnits} ${extraOpp.tradeSymbol} -> '
          '${extraOpp.waypointSymbol} @ ${creditsString(extraOpp.price)}');
    }
  }

  final marketScan = scanReachableMarkets(
    systemsCache,
    systemConnectivity,
    marketPrices,
    startSystem: start.system,
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
    startSymbol: start.symbol,
    extraSellOpps: extraSellOpps,
  );

  if (deals.isEmpty) {
    logger.info('No deal found.');
    return;
  }

  final dealNotInProgress =
      avoidDealsInProgress(behaviorCache.dealsInProgress());

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
    (deal) => deal.deal.withinSystem(start.system),
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

    final inProgresMarker = dealNotInProgress(deal) ? '' : '*';

    table.add([
      '$name$inProgresMarker',
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

  await db.close();
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
