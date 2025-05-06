import 'package:cli/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/config.dart';
import 'package:cli/nav/navigation.dart';
import 'package:cli/plan/trading.dart';
import 'package:collection/collection.dart';

Future<void> command(Database db, ArgResults argResults) async {
  // First need to figure out which systems are worth checking.

  final systems = await db.snapshotAllSystems();
  final systemConnectivity = await loadSystemConnectivity(db);
  final marketPrices = await MarketPriceSnapshot.loadAll(db);
  final agentCache = await AgentCache.load(db);
  final marketListings = await MarketListingSnapshot.load(db);
  final routePlanner = RoutePlanner.fromSystemsSnapshot(
    systems,
    systemConnectivity,
    sellsFuel: defaultSellsFuel(marketListings),
  );
  final startSystem = agentCache!.headquartersSystemSymbol;
  const shipType = ShipType.REFINING_FREIGHTER;

  final shipyardShips = ShipyardShipCache(db);
  final ship = await shipyardShips.get(shipType);
  final shipSpec = ship!.shipSpec;
  const minProfitPerSecond = 5;

  // First want to understand what slots are available.
  // Then go through all our haulers and assign them to the best slots.
  // Slots are per-system, possibly also per-ship-type?
  // A slot is defined as the # of deals available from a example waypoint
  // (e.g. jumpgate or center) within a system, above a certain c/s threshold.

  // Find all trades available across all systems.
  final marketScan = scanReachableMarkets(
    systemConnectivity,
    marketPrices,
    // start system is just used for reachability.
    startSystem: startSystem,
  );

  logger.info('Opps for ${marketScan.tradeSymbols.length} trade symbols.');
  final costPerFuelUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
      config.defaultFuelCost;
  final costPerAntimatterUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
      config.defaultAntimatterCost;

  final deals = findAllDeals(
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

  final ships = await ShipSnapshot.load(db);
  final behaviors = await BehaviorSnapshot.load(db);
  final haulers = ships.ships.where((ship) => ship.isHauler);
  final haulersBySystem = <SystemSymbol, Set<ShipSymbol>>{};
  for (final hauler in haulers) {
    final system = hauler.systemSymbol;
    haulersBySystem.putIfAbsent(system, () => {}).add(hauler.symbol);
    final state = behaviors[hauler.symbol];
    if (state != null) {
      final route = state.routePlan;
      if (route != null) {
        final system = route.endSymbol.system;
        haulersBySystem.putIfAbsent(system, () => {}).add(hauler.symbol);
      }
    }
  }

  const minScore = 2;
  double scoreSystem(SystemSymbol system) {
    final deals = dealsBySystem[system] ?? [];
    final haulers = haulersBySystem[system] ?? {};
    return deals.length / (haulers.length + 1);
  }

  logger.info('Deals above $minProfitPerSecond c/s by system:');
  final systemSymbolsWithDealsSorted =
      dealsBySystem.keys.toList()
        ..sort((a, b) => dealsBySystem[b]!.length - dealsBySystem[a]!.length);
  for (final system in systemSymbolsWithDealsSorted) {
    final deals = dealsBySystem[system]!;
    final haulers = haulersBySystem[system] ?? {};
    final score = scoreSystem(system);
    logger.info(
      '${system.systemName} : ${deals.length} deals, '
      '${haulers.length} haulers, score: ${score.toStringAsFixed(2)}',
    );
  }
  logger.info('Total deals: ${deals.length}');

  final idleHaulers =
      haulers
          .where((ship) {
            final state = behaviors[ship.symbol];
            return state == null || state.behavior == Behavior.idle;
          })
          .map((e) => e.symbol)
          .toList();
  logger.info('Idle haulers: ${idleHaulers.length}');

  // First figure out if we have any traders needing reassignment.
  // If so, compute possible trades for systems near them with markets?

  for (final shipSymbol in idleHaulers) {
    // Re-compute since assignments may have changed.
    final systemsWithOpenSlots = await Future.wait(
      systemSymbolsWithDealsSorted
          .where((system) => scoreSystem(system) > minScore)
          .map(
            (symbol) async => (await db.systems.systemRecordBySymbol(symbol))!,
          )
          .toList(),
    );

    final shipSystem = await db.systems.systemRecordBySymbol(
      ships[shipSymbol]!.systemSymbol,
    );
    final closest = minBy(
      systemsWithOpenSlots,
      (system) => system.distanceTo(shipSystem!),
    );
    if (closest != null) {
      // Pick the jumpgate in that system.
      final jumpGate = await db.systems.jumpGateSymbolForSystem(closest.symbol);
      // route there.
      haulersBySystem.putIfAbsent(closest.symbol, () => {}).add(shipSymbol);
      final ship = ships[shipSymbol]!;
      final route = routePlanner.planRoute(
        shipSpec,
        start: ship.waypointSymbol,
        end: jumpGate!,
      );
      final planString = route != null ? describeRoutePlan(route) : 'none';
      logger
        ..info('Should route $shipSymbol to $jumpGate')
        ..info(planString);
    }
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
