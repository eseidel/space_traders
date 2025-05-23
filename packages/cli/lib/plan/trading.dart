import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/plan/market_scan.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/prediction.dart';
import 'package:types/types.dart';

/// Builds a list of deals found from the provided MarketScan.
List<Deal> buildDealsFromScan(
  MarketScan scan, {
  List<SellOpp>? extraSellOpps,
  int? minProfitPerUnit,
}) {
  final deals = <Deal>[];
  final tradeSymbols = scan.tradeSymbols;
  for (final tradeSymbol in tradeSymbols) {
    final buys = scan.buyOppsForTradeSymbol(tradeSymbol);
    final scanSells = scan.sellOppsForTradeSymbol(tradeSymbol);
    final sells = extraSellOpps != null
        ? [
            ...scanSells,
            ...extraSellOpps.where((o) => o.tradeSymbol == tradeSymbol),
          ]
        : scanSells;
    for (final buy in buys) {
      for (final sell in sells) {
        if (buy.waypointSymbol == sell.waypointSymbol) {
          continue;
        }
        final profit = sell.price - buy.price;
        if (minProfitPerUnit != null && profit <= minProfitPerUnit) {
          continue;
        }
        deals.add(Deal(source: buy, destination: sell));
      }
    }
  }
  return deals;
}

/// Returns a string describing the given CostedDeal
String describeCostedDeal(CostedDeal costedDeal) {
  const c = creditsString;
  final deal = costedDeal.deal;
  final profit = costedDeal.expectedProfit;
  final sign = profit > 0 ? '+' : '';
  final profitPercent = (profit / costedDeal.expectedCosts) * 100;
  final profitCreditsString = '$sign${c(profit)}'.padLeft(9);
  final profitPercentString = '(${profitPercent.toStringAsFixed(0)}%)'.padLeft(
    5,
  );
  final profitString = '$profitCreditsString $profitPercentString';
  final coloredProfitString = profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  final timeString =
      '${approximateDuration(costedDeal.expectedTime)} '
      '${c(costedDeal.expectedProfitPerSecond).padLeft(4)}/s';
  final tradeSymbol = deal.tradeSymbol.value;
  final name = costedDeal.isContractDeal
      ? '$tradeSymbol (contract)'
      : tradeSymbol;
  return '${name.padRight(25)} '
      ' ${deal.sourceSymbol.sectorLocalName.padRight(11)} '
      // This could use the average expected purchase/sell price across the
      // whole deal volume.
      '${c(costedDeal.expectedInitialBuyPrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol.sectorLocalName.padRight(11)} '
      '${c(costedDeal.expectedInitialSellPrice).padLeft(8)} '
      '$coloredProfitString $timeString '
      '${c(costedDeal.expectedCosts).padLeft(8)}';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  RoutePlanner routePlanner,
  ShipSpec shipSpec,
  Deal deal, {
  required WaypointSymbol shipWaypointSymbol,
  required int costPerFuelUnit,
  required int costPerAntimatterUnit,
}) {
  final waypointSymbols = [
    shipWaypointSymbol,
    deal.sourceSymbol,
    deal.destinationSymbol,
  ];
  final route = planRouteThrough(routePlanner, shipSpec, waypointSymbols);

  if (route == null) {
    for (final symbol in waypointSymbols) {
      final clusterId = routePlanner.systemConnectivity.clusterIdForSystem(
        symbol.system,
      );
      logger.info('Cluster $clusterId: ${symbol.system}');
    }
    throw Exception('No route found for $deal through $waypointSymbols');
  }

  return CostedDeal(
    deal: deal,
    cargoSize: shipSpec.cargoCapacity,
    transactions: [],
    startTime: DateTime.timestamp(),
    route: route,
    costPerFuelUnit: costPerFuelUnit,
    costPerAntimatterUnit: costPerAntimatterUnit,
  );
}

/// Builds a MarketScan from all known markets.
MarketScan scanReachableMarkets(
  SystemConnectivity systemConnectivity,
  MarketPriceSnapshot marketPrices, {
  required SystemSymbol startSystem,
}) {
  return MarketScan.fromMarketPrices(
    marketPrices,
    waypointFilter: (w) =>
        systemConnectivity.existsJumpPathBetween(w.system, startSystem),
    description: 'all known markets',
  );
}

/// Returns the best deals for the given parameters,
/// sorted by profit per second, with most profitable first.
Iterable<CostedDeal> findDealsFor(
  RoutePlanner routePlanner,
  MarketScan scan, {
  required WaypointSymbol startSymbol,
  required ShipSpec shipSpec,
  required int maxTotalOutlay,
  required int costPerAntimatterUnit,
  required int costPerFuelUnit,
  List<SellOpp>? extraSellOpps,
  bool Function(Deal deal)? filter,
  int minProfitPerSecond = 0,
}) {
  logger.detail(
    'Finding deals with '
    'start: $startSymbol, '
    'from scan: ${scan.description}, '
    'max outlay: $maxTotalOutlay, '
    'max units: ${shipSpec.cargoCapacity}, '
    'fuel capacity: ${shipSpec.fuelCapacity}, '
    'ship speed: ${shipSpec.speed}, ',
  );
  // Allow negative unit profits in search when we're allowing negative
  // per-second profits.
  final minProfitPerUnit = (minProfitPerSecond < 0) ? null : 0;
  final deals = buildDealsFromScan(
    scan,
    extraSellOpps: extraSellOpps,
    minProfitPerUnit: minProfitPerUnit,
  );
  logger.detail('Found ${deals.length} potential deals.');

  final filtered = filter != null ? deals.where(filter) : deals;

  final withinRange = 'within ${scan.description}';
  if (filtered.isEmpty) {
    logger.detail('No deals $withinRange.');
    return [];
  }

  final before = DateTime.timestamp();
  final costedDeals = filtered
      .map(
        (deal) => costOutDeal(
          routePlanner,
          shipSpec,
          deal,
          shipWaypointSymbol: startSymbol,
          costPerFuelUnit: costPerFuelUnit,
          costPerAntimatterUnit: costPerAntimatterUnit,
        ),
      )
      .toList();

  // toList is used to force resolution of the list before we log.
  final after = DateTime.timestamp();
  final elapsed = after.difference(before);
  if (elapsed > const Duration(milliseconds: 300)) {
    logger.warn(
      'Costed ${deals.length} deals in ${approximateDuration(elapsed)}',
    );
  }

  final affordable = costedDeals
      .map((d) => d.limitUnitsByMaxSpend(maxTotalOutlay))
      .where((d) => d.cargoSize > 0)
      // TODO(eseidel): This should not be necessary, limitUnitsByMaxSpend
      // should have already done this.
      .where((d) => d.expectedCosts <= maxTotalOutlay)
      .toList();
  if (affordable.isEmpty) {
    logger.info('No deals < ${creditsString(maxTotalOutlay)} $withinRange.');
    return [];
  }

  return affordable
      .sortedBy<num>((e) => -e.expectedProfitPerSecond)
      .where((d) => d.expectedProfitPerSecond > minProfitPerSecond);
}

/// Returns all deals for the given scan, assuming each starts from the deal's
/// own source.  Used for planning trader spacing across the entire universe.
Iterable<CostedDeal> findAllDeals(
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
          routePlanner,
          shipSpec,
          deal,
          // TODO(eseidel): Use something other than the deal source?
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

/// Calculated trip cost of going and buying something.
class CostedTrip<Price> {
  /// Create a new costed trip.
  CostedTrip({required this.route, required this.price});

  /// The route to get there.
  final RoutePlan route;

  /// The price of the item at the destination.
  final Price price;

  @override
  String toString() => '$price in ${route.duration}';
}

/// A trip to a market.
typedef MarketTrip = CostedTrip<MarketPrice>;

/// Compute the cost of going to and buying from a specific MarketPrice record.
CostedTrip<T>? costTrip<T>(
  RoutePlanner planner,
  T price,
  ShipSpec shipSpec, {
  required WaypointSymbol start,
  required WaypointSymbol end,
}) {
  final route = planner.planRoute(shipSpec, start: start, end: end);
  if (route == null) {
    return null;
  }
  return CostedTrip(route: route, price: price);
}

/// Returns a list of MarketTrips for markets which trade the given symbol
/// sorted by distance.
List<MarketTrip> marketsTradingSortedByDistance(
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner,
  TradeSymbol tradeSymbol, {
  required WaypointSymbol start,
  required ShipSpec shipSpec,
}) {
  final prices = marketPrices.pricesFor(tradeSymbol).toList();
  if (prices.isEmpty) {
    return [];
  }
  // If there are a lot of prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = <MarketTrip>[];
  for (final price in prices) {
    final end = price.waypointSymbol;
    final trip = costTrip<MarketPrice>(
      routePlanner,
      price,
      shipSpec,
      start: start,
      end: end,
    );
    if (trip != null) {
      costed.add(trip);
    } else {
      logger.warn('No route from $start to $end');
    }
  }

  final sorted = costed.toList()
    ..sort((a, b) => a.route.duration.compareTo(b.route.duration));
  return sorted;
}

/// Find the best market to buy a given item from.
/// expectedCreditsPerSecond is the time value of money (e.g. 7c/s)
/// used for evaluating the trade-off between "closest" vs. "cheapest".
MarketTrip? findBestMarketToBuy(
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner,
  TradeSymbol tradeSymbol, {
  required WaypointSymbol start,
  required ShipSpec shipSpec,
  required int expectedCreditsPerSecond,
}) {
  final sorted = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: start,
    shipSpec: shipSpec,
  );
  if (sorted.isEmpty) {
    return null;
  }
  final nearest = sorted.first;
  var best = nearest;
  // Pick any one further that saves more than expectedCreditsPerSecond
  // TODO(eseidel): This does not take fuel costs into account.
  // That might be OK? since it should be a constant multiplier?
  for (final trip in sorted.sublist(1)) {
    final priceDiff = trip.price.purchasePrice - nearest.price.purchasePrice;
    final savings = -priceDiff;
    final extraTime = trip.route.duration - nearest.route.duration;
    final savingsPerSecond = savings / extraTime.inSeconds;
    if (savingsPerSecond > expectedCreditsPerSecond) {
      best = trip;
      break;
    }
  }

  return best;
}

/// Returns the cost of a route plan in credits.
int estimateRoutePlanCost({
  required RoutePlan route,
  required int costPerFuelUnit,
  required int costPerAntimatterUnit,
}) {
  final fuelCost = fuelUsedCost(
    tankUnits: route.fuelUsed,
    costPerMarketFuelUnit: costPerFuelUnit,
  );
  final antimatterCost = costPerAntimatterUnit * route.antimatterUsed;
  return fuelCost + antimatterCost;
}

/// Find the best market to sell a given item to.
/// expectedCreditsPerSecond is the time value of money (e.g. 7c/s)
/// used for evaluating the trade-off between "closest" vs. "cheapest".
/// This does not account for fuel costs.
// TODO(eseidel): This does not work with no pricing data.
Future<MarketTrip?> findBestMarketToSell(
  Database db,
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner,
  Ship ship,
  TradeSymbol tradeSymbol, {
  required int expectedCreditsPerSecond,
  required int unitsToSell,

  /// Used to express the minimum time until the next action.  This is useful
  /// for modeling when the next thing we plan to do involves the cooldown and
  /// lets us consider longer routes as the same cost as shorter routes.
  Duration? minimumDuration,

  /// If true, we'll include the cost of returning to the current location
  /// in the calculation, which makes longer distances less attractive.
  bool includeRoundTripCost = false,

  /// If true, we'll require that the destination market has fuel for sale
  /// otherwise we'll skip it.  This should probably always be true
  /// but leaving it as an option for now to not break existing callers.
  bool requireFuelAtDestination = false,
}) async {
  // Some callers might want to use a round trip cost?
  // e.g. if just trying to empty inventory and return to current location.
  final sorted = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: ship.waypointSymbol,
    shipSpec: ship.shipSpec,
  );
  if (sorted.isEmpty) {
    return null;
  }
  Duration applyMin(Duration duration) {
    return minimumDuration == null || duration > minimumDuration
        ? duration
        : minimumDuration;
  }

  var printCount = 3;
  void info(String message) {
    if (printCount > 0) {
      shipInfo(ship, message);
    }
  }

  void detail(String message) {
    if (printCount > 0) {
      shipDetail(ship, message);
    }
  }

  final roundTripMultiplier = includeRoundTripCost ? 2 : 1;
  final nearest = sorted.first;
  // We could do per-destination fuel cost planning, but that seems overkill.
  final costPerFuelUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ?? 100;
  final costPerUnitAntimatter =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ?? 10000;

  int estimateTripCost(MarketTrip trip) {
    return estimateRoutePlanCost(
      route: trip.route,
      costPerFuelUnit: costPerFuelUnit,
      costPerAntimatterUnit: costPerUnitAntimatter,
    );
  }

  var best = nearest;
  // Pick any one further that earns more than expectedCreditsPerSecond
  for (final trip in sorted.sublist(1)) {
    if (requireFuelAtDestination &&
        !(await db.marketListings.sellsFuel(trip.price.waypointSymbol))) {
      detail('Skipping ${trip.price.waypointSymbol} due to no fuel');
      continue;
    }

    final priceDiff = trip.price.sellPrice - nearest.price.sellPrice;
    final extraEarnings = priceDiff * unitsToSell;
    final extraTime =
        applyMin(trip.route.duration) - applyMin(nearest.route.duration);

    final nearestCost = estimateTripCost(nearest);
    final tripCost = estimateTripCost(trip);
    final extraFuelCost = tripCost - nearestCost;

    // TODO(eseidel): if extraTime is zero, earningsPerSecond ends up infinity.
    // In that case we want to compare absolute earnings of trip vs. nearest.
    // That would require refactoring our fuel cost logic to be used as part
    // of computing the absolute earnings for nearest.
    final earningsPerSecond =
        extraEarnings / (extraTime.inSeconds * roundTripMultiplier);
    if (earningsPerSecond > expectedCreditsPerSecond) {
      info(
        'Selecting ${trip.price.waypointSymbol} earns '
        '${creditsString(extraEarnings)} extra '
        '(including ${creditsString(-extraFuelCost)} for fuel) '
        'over ${approximateDuration(extraTime)} '
        '(${earningsPerSecond.toStringAsFixed(1)}/s)',
      );
      best = trip;
      break;
    } else {
      detail(
        'Skipping ${trip.price.waypointSymbol} earns '
        '${creditsString(extraEarnings)} extra '
        '(${creditsString(-extraFuelCost)} for fuel) '
        'for ${approximateDuration(extraTime)} '
        '(${earningsPerSecond.toStringAsFixed(1)}/s)',
      );
    }
    printCount--;
  }

  return best;
}

/// Returns a deal filter function which avoids deals in progress.
/// Optionally takes an additional [filter] function to apply.
bool Function(Deal) avoidDealsInProgress(
  Iterable<CostedDeal> dealsInProgress, {
  bool Function(Deal)? filter,
}) {
  // Avoid having two ships working on the same deal since by the time the
  // second one gets there the prices will have changed.
  // Note this does not check destination, so should still allow two
  // ships to work on the same contract.
  // We could consider enforcing destination difference for arbitrage deals.
  return (Deal deal) {
    return dealsInProgress.every((d) {
      // Deals need to differ in their source *or* their trade symbol
      // for us to consider them.
      if (d.deal.sourceSymbol == deal.sourceSymbol &&
          d.deal.tradeSymbol == deal.tradeSymbol
          // Sometimes we want to allow parallel construction deliveries
          // as a hack to let construction finish faster.  If that's not the
          // case or this is not a construction delivery, than we should enforce
          // our no-parallel rule.
          &&
          (!config.allowParallelConstructionDelivery ||
              !d.deal.isConstructionDelivery)) {
        return false;
      }
      return filter?.call(deal) ?? true;
    });
  };
}

/// This is visible for scripts, generally you want to use
/// CentralCommand.findNextDealAndLog instead.
Iterable<CostedDeal> scanAndFindDeals(
  SystemConnectivity systemConnectivity,
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner, {
  required WaypointSymbol startSymbol,
  required int maxTotalOutlay,
  required ShipSpec shipSpec,
  required int costPerFuelUnit,
  required int costPerAntimatterUnit,
  bool Function(Deal)? filter,
  List<SellOpp>? extraSellOpps,
  int minProfitPerSecond = 0,
}) {
  final marketScan = scanReachableMarkets(
    systemConnectivity,
    marketPrices,
    startSystem: startSymbol.system,
  );
  return findDealsFor(
    routePlanner,
    marketScan,
    maxTotalOutlay: maxTotalOutlay,
    extraSellOpps: extraSellOpps,
    filter: filter,
    startSymbol: startSymbol,
    shipSpec: shipSpec,
    minProfitPerSecond: minProfitPerSecond,
    costPerAntimatterUnit: costPerAntimatterUnit,
    costPerFuelUnit: costPerFuelUnit,
  );
}
