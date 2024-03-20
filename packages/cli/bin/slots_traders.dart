import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/market_scan.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';

Iterable<CostedDeal> findAllDeals(
  MarketPriceSnapshot marketPrices,
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  MarketScan scan, {
  required ShipSpec shipSpec,
  required int maxTotalOutlay,
  required int costPerAntimatterUnit,
  required int costPerFuelUnit,
  required int minProfitPerSecond,
}) {
  final deals = buildDealsFromScan(
    scan,
    // Don't allow negative profit deals.
    minProfitPerUnit: 0,
  );
  logger.info('Found ${deals.length} potential deals.');

  final costedDeals = deals
      .map(
        (deal) => costOutDeal(
          systemsCache,
          routePlanner,
          shipSpec,
          deal,
          // TODO(eseidel): Should this be something other than the deal source?
          shipWaypointSymbol: deal.sourceSymbol,
          costPerFuelUnit: costPerFuelUnit,
          costPerAntimatterUnit: costPerAntimatterUnit,
        ),
      )
      .toList();

  final affordable = costedDeals
      .map((d) => d.limitUnitsByMaxSpend(maxTotalOutlay))
      .where((d) => d.cargoSize > 0)
      // TODO(eseidel): This should not be necessary, limitUnitsByMaxSpend
      // should have already done this.
      .where((d) => d.expectedCosts <= maxTotalOutlay)
      .toList();

  return affordable
      .sortedBy<num>((e) => -e.expectedProfitPerSecond)
      .where((d) => d.expectedProfitPerSecond > minProfitPerSecond);
}

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  // First need to figure out which systems are worth checking.

  final systems = SystemsCache.load(fs);
  final systemConnectivity = await loadSystemConnectivity(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final agentCache = await AgentCache.load(db);
  final marketListings = await MarketListingSnapshot.load(db);
  final routePlanner = RoutePlanner.fromSystemsCache(
    systems!,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final startSystem = agentCache!.headquartersSystemSymbol;
  const shipType = ShipType.LIGHT_HAULER;

  final shipyardShips = ShipyardShipCache.load(fs);
  final ship = shipyardShips[shipType]!;
  final shipSpec = ship.shipSpec;
  const minProfitPerSecond = 5;

  // First want to understand what slots are available.
  // Then go through all our haulers and assign them to the best slots.
  // Slots are per-system, possibly also per-ship-type?
  // A slot is defined as the # of deals available from a example waypoint
  // (e.g. jumpgate or center) within a system, above a certain c/s threshold.

  // Find all trades available across all systems.
  final marketScan = scanReachableMarkets(
    systems,
    systemConnectivity,
    marketPrices,
    // start system is just used for reachability.
    startSystem: startSystem,
  );

  logger.info('Opps for ${marketScan.tradeSymbols.length} trade symbols.');
  final costPerFuelUnit = marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
      config.defaultFuelCost;
  final costPerAntimatterUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
          config.defaultAntimatterCost;

  final deals = findAllDeals(
    marketPrices,
    systems,
    routePlanner,
    marketScan,
    shipSpec: shipSpec,
    maxTotalOutlay: 1000000,
    costPerAntimatterUnit: costPerAntimatterUnit,
    costPerFuelUnit: costPerFuelUnit,
    minProfitPerSecond: minProfitPerSecond,
  );

  // Then look at trades starting from a given system.
  // If the trade is > 5 c/s, then we consider it a "slot"

  final dealsBySystem = groupBy<CostedDeal, SystemSymbol>(
    deals,
    (deal) => deal.deal.source.waypointSymbol.system,
  );

  logger.info('Deals above $minProfitPerSecond c/s by system:');
  for (final system in dealsBySystem.keys) {
    final deals = dealsBySystem[system]!;
    logger.info('${system.systemName} : ${deals.length}');
  }

  // First figure out if we have any traders needing reassignment.
  // If so, compute possible trades for systems near them with markets?
}

void main(List<String> args) async {
  await runOffline(args, command);
}
