import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';
import 'package:cli_table/cli_table.dart';

Future<void> cliMain(FileSystem fs, Database db, ArgResults argResults) async {
  final shipType = shipTypeFromArg(argResults['ship'] as String);
  final limit = int.parse(argResults['limit'] as String);
  final startArg = argResults['start'] as String?;
  final credits = int.parse(argResults['credits'] as String);

  final systemsCache = SystemsCache.load(fs);
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
  final marketPrices = await MarketPriceSnapshot.loadAll(db);

  final agentCache = await AgentCache.load(db);
  final contractSnapshot = await ContractSnapshot.load(db);
  final centralCommand = CentralCommand();

  final start = startArg == null
      ? agentCache!.headquarters(systemsCache)
      : systemsCache.waypointFromString(startArg)!;

  final construction = await centralCommand.computeActiveConstruction(
    db,
    agentCache!,
    systemsCache,
  );
  centralCommand.activeConstruction = construction;

  final exportCache = TradeExportCache.load(fs);
  final behaviors = await BehaviorSnapshot.load(db);
  final charting = await ChartingSnapshot.load(db);

  if (construction != null) {
    centralCommand.subsidizedSellOpps =
        await computeConstructionMaterialSubsidies(
      db,
      systemsCache,
      exportCache,
      marketListings,
      charting,
      construction,
    );
  }

  final extraSellOpps = <SellOpp>[];
  if (centralCommand.isContractTradingEnabled) {
    extraSellOpps.addAll(
      centralCommand.contractSellOpps(
        agentCache,
        behaviors,
        contractSnapshot,
      ),
    );
  }
  if (centralCommand.isConstructionTradingEnabled) {
    extraSellOpps.addAll(centralCommand.constructionSellOpps(behaviors));
  }

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;

  logger.info('$shipType @ ${start.symbol}, '
      'speed = ${shipSpec.speed} '
      'capacity = ${shipSpec.cargoCapacity}, '
      'fuel <= ${shipSpec.fuelCapacity}, '
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
  final costPerFuelUnit = marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
      config.defaultFuelCost;
  final costPerAntimatterUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
          config.defaultAntimatterCost;

  final deals = findDealsFor(
    systemsCache,
    routePlanner,
    marketScan,
    maxTotalOutlay: credits,
    shipSpec: shipSpec,
    startSymbol: start.symbol,
    extraSellOpps: extraSellOpps,
    costPerAntimatterUnit: costPerAntimatterUnit,
    costPerFuelUnit: costPerFuelUnit,
  );

  if (deals.isEmpty) {
    logger.info('No deal found.');
    return;
  }

  final dealNotInProgress = avoidDealsInProgress(behaviors.dealsInProgress());

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

    final inProgressMarker = dealNotInProgress(deal) ? '' : '*';

    table.add([
      '$name$inProgressMarker',
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
