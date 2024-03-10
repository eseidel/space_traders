import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // final systems = SystemsCache.load(fs);
  // final systemConnectivity = await loadSystemConnectivity(db);
  // final marketPrices = await MarketPriceSnapshot.load(db);
  // final agentCache = await AgentCache.load(db);
  // final contractSnapshot = await ContractSnapshot.load(db);
  // final marketListings = await MarketListingSnapshot.load(db);
  // final routePlanner = RoutePlanner.fromSystemsCache(
  //   systems!,
  //   systemConnectivity,
  //   sellsFuel: defaultSellsFuel(marketListings),
  // );

  // final behaviors = await BehaviorSnapshot.load(db);
  // final ships = await ShipSnapshot.load(db);
  // final centralCommand = CentralCommand();

  // final extraSellOpps = <SellOpp>[];
  // if (centralCommand.isConstructionTradingEnabled) {
  //   extraSellOpps.addAll(centralCommand.constructionSellOpps(behaviors));
  // }
  // if (centralCommand.isContractTradingEnabled) {
  //   extraSellOpps.addAll(
  //     centralCommand.contractSellOpps(
  //       agentCache!,
  //       behaviors,
  //       contractSnapshot,
  //     ),
  //   );
  // }
  // if (extraSellOpps.isNotEmpty) {
  //   final opp = extraSellOpps.first;
  //   logger.detail(
  //     'Including contract sell opp: ${opp.maxUnits} ${opp.tradeSymbol} '
  //     '@ ${creditsString(opp.price)} -> ${opp.waypointSymbol}',
  //   );
  // }

  // // Probably save per-cluster scans?
  // final scan = scanReachableMarkets(
  //   systems,
  //   systemConnectivity,
  //   marketPrices,
  //   startSystem: agentCache!.headquartersSystemSymbol,
  // );
  // final deals = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);

  // final deals = findDealsFor(
  //   marketPrices,
  //   systems,
  //   routePlanner,
  //   scan,
  //   maxTotalOutlay: 10000000,
  //   extraSellOpps: extraSellOpps,
  //   startSymbol: startSymbol,
  //   shipSpec: shipSpec,
  //   minProfitPerSecond: minProfitPerSecond,
  // );

  // // final deals = scanAndFindDeals(
  // //   systemsCache,
  // //   systemConnectivity,
  // //   marketPrices,
  // //   routePlanner,
  // //   maxTotalOutlay: maxTotalOutlay,
  // //   startSymbol: startSymbol,
  // //   extraSellOpps: extraSellOpps,
  // //   shipSpec: ship.shipSpec,
  // //   filter: avoidDealsInProgress(behaviors.dealsInProgress()),
  // // );

  // // A hack to avoid spamming the console until we add a deals cache.
  // if (deals.isNotEmpty) {
  //   logger.info('Found ${deals.length} deals for ${ship.symbol} from '
  //       '$startSymbol');
  // }
  // for (final deal in deals) {
  //   logger.detail(describeCostedDeal(deal));
  // }
  // return deals.firstOrNull;
}

void main(List<String> args) async {
  await runOffline(args, command);
}
