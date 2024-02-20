import 'dart:math';

import 'package:cli/cache/market_listing_snapshot.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
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

/// How many units can we trade between these markets before the price
/// drop below our expected profit margin?
int profitableVolumeBetween(
  MarketPrice a,
  MarketPrice b, {
  required int maxVolume,
  int minimumUnitProfit = 0,
}) {
  var units = 0;
  while (true) {
    // This is N^2 for the trade volume, which should be fine for now.
    final aPrice = a.predictPurchasePriceForUnit(units);
    final bPrice = b.predictSellPriceForUnit(units);
    final profit = bPrice - aPrice;
    if (profit <= minimumUnitProfit) {
      return units;
    }
    units++;
    // Some goods change in price very slowly, so we need to cap the max
    // volume we'll consider or we'll loop forever.
    if (units >= maxVolume) {
      return maxVolume;
    }
  }
}

/// Logic for extrapolating from a MarketPrice
extension SellOppPrediction on SellOpp {
  /// The total sell price for the given number of units.
  int totalSellPriceFor(int units) {
    // Contract rewards don't move with market state.
    if (isConstructionDelivery || isContractDelivery) {
      return price * units;
    }
    return marketPrice!.totalSellPriceFor(units);
  }
}

/// Logic for extrapolating from a CostedDeal
extension CostedDealPrediction on CostedDeal {
  /// expectedUnits uses cargoSize instead of maxUnitsToBuy when computing
  /// pricing to avoid having contracts never finish due to only needing one
  /// more unit yet that unit not being worth carrying in an otherwise empty
  /// ship.
  int get expectedUnits {
    if (isContractDeal || isConstructionDeal || isFeeder) {
      return cargoSize;
    }
    return min(
      cargoSize,
      profitableVolumeBetween(
        deal.source.marketPrice,
        deal.destination.marketPrice!,
        maxVolume: cargoSize,
      ),
    );
  }

  /// The max number of units of cargo to buy. This must be less than or equal
  /// to the Deal.maxUnits (if set) and expectedUnits and accounts for contracts
  /// which only take up to a certain number of units as well as cargo size
  /// (expectedUnits).
  /// We can't inflate the price of the units towards the end of the contract
  /// without causing us to over-spend, so we instead inflate the number
  /// we're expected to buy (by not reducing to maxUnits) to allow those last
  /// few units to look profitable during planning and not let contracts stall.
  int get maxUnitsToBuy => deal.maxUnits != null
      ? min(deal.maxUnits!, expectedUnits)
      : expectedUnits;

  /// The expected cost of goods sold, not including fuel.
  int get expectedCostOfGoodsSold =>
      deal.source.marketPrice.totalPurchasePriceFor(expectedUnits);

  /// The expected non-goods expenses of the deal, including fuel.
  int get expectedOperationalExpenses =>
      expectedFuelCost + expectedAntimatterCost;

  /// The total upfront cost of the deal, including fuel.
  int get expectedCosts =>
      expectedCostOfGoodsSold + expectedOperationalExpenses;

  /// The total income of the deal, excluding any costs.
  int get expectedRevenue => deal.destination.totalSellPriceFor(expectedUnits);

  /// The expected initial per-unit buy price.
  // No prediction is needed for the first price.
  int get expectedInitialBuyPrice => deal.source.price;

  /// The expected initial per-unit sell price.
  // No prediction is needed for the first price.
  int get expectedInitialSellPrice => deal.destination.price;

  /// Max we would spend per unit and still expect to break even.
  int? get maxPurchaseUnitPrice {
    if (deal.isFeeder) {
      // We will spend any amount in a feeder deal.
      return null;
    }
    return (expectedRevenue - expectedOperationalExpenses) ~/ expectedUnits;
  }

  /// Count of units purchased so far.
  int get unitsPurchased => transactions
      .where(
        (t) =>
            t.tradeType == MarketTransactionTypeEnum.PURCHASE &&
            t.accounting == AccountingType.goods,
      )
      .fold(0, (a, b) => a + b.quantity);

  /// The next expected purchase price.
  int get predictNextPurchasePrice {
    if (isContractDeal) {
      // Contract deals don't move with market state.
      // TODO(eseidel): This is just wrong.  Contract sources do move!
      return deal.source.marketPrice.purchasePrice;
    }
    return deal.source.marketPrice
        .predictPurchasePriceForUnit(unitsPurchased + 1);
  }

  /// The total profit of the deal, including fuel.
  int get expectedProfit => expectedRevenue - expectedCosts;

  /// The profit per second of the deal.
  int get expectedProfitPerSecond {
    final seconds = expectedTime.inSeconds;
    if (seconds < 1) {
      return expectedProfit;
    }
    return expectedProfit ~/ seconds;
  }

  /// The actual time taken to complete the deal.
  Duration get actualTime => transactions.last.timestamp.difference(startTime);

  /// The actual revenue of the deal.
  int get actualRevenue {
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.SELL)
        .fold(0, (a, b) => a + b.creditsChange);
  }

  /// The actual cost of goods sold.
  int get actualCostOfGoodsSold {
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.PURCHASE)
        .where((t) => t.accounting == AccountingType.goods)
        .fold(0, (a, b) => a + -b.creditsChange);
  }

  /// The actual operational expenses of the deal.
  int get actualOperationalExpenses {
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.PURCHASE)
        .where((t) => t.accounting == AccountingType.fuel)
        .fold(0, (a, b) => a + -b.creditsChange);
  }

  /// The actual profit of the deal.
  int get actualProfit =>
      actualRevenue - actualCostOfGoodsSold - actualOperationalExpenses;

  /// The actual profit per second of the deal.
  int get actualProfitPerSecond {
    final actualSeconds = actualTime.inSeconds;
    if (actualSeconds == 0) {
      return actualProfit;
    }
    return actualProfit ~/ actualSeconds;
  }

  /// Get a limited version of this CostedDeal by limiting the number of units
  /// of cargo to the given maxSpend.
  CostedDeal limitUnitsByMaxSpend(int maxSpend) {
    final goodsBudget = maxSpend - expectedOperationalExpenses;
    final affordableUnits = deal.source.marketPrice
        .predictUnitsPurchasableFor(maxSpend: goodsBudget, maxUnits: cargoSize);
    if (affordableUnits < cargoSize) {
      return CostedDeal(
        deal: deal,
        cargoSize: affordableUnits,
        transactions: transactions,
        startTime: startTime,
        route: route,
        costPerFuelUnit: costPerFuelUnit,
        costPerAntimatterUnit: costPerAntimatterUnit,
      );
    }
    return this;
  }
}

/// Returns a string describing the given CostedDeal
String describeCostedDeal(CostedDeal costedDeal) {
  const c = creditsString;
  final deal = costedDeal.deal;
  final profit = costedDeal.expectedProfit;
  final sign = profit > 0 ? '+' : '';
  final profitPercent = (profit / costedDeal.expectedCosts) * 100;
  final profitCreditsString = '$sign${c(profit)}'.padLeft(9);
  final profitPercentString =
      '(${profitPercent.toStringAsFixed(0)}%)'.padLeft(5);
  final profitString = '$profitCreditsString $profitPercentString';
  final coloredProfitString =
      profit > 0 ? lightGreen.wrap(profitString) : lightRed.wrap(profitString);
  final timeString = '${approximateDuration(costedDeal.expectedTime)} '
      '${c(costedDeal.expectedProfitPerSecond).padLeft(4)}/s';
  final tradeSymbol = deal.tradeSymbol.value;
  final name =
      costedDeal.isContractDeal ? '$tradeSymbol (contract)' : tradeSymbol;
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
  SystemsCache systemsCache,
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
  final route = planRouteThrough(
    systemsCache,
    routePlanner,
    shipSpec,
    waypointSymbols,
  );

  if (route == null) {
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
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  MarketPriceSnapshot marketPrices, {
  required SystemSymbol startSystem,
}) {
  // Reachable systems will all have the same clusterId as the start system.
  final clusterId = systemConnectivity.clusterIdForSystem(startSystem);
  return MarketScan.fromMarketPrices(
    marketPrices,
    waypointFilter: (w) =>
        systemConnectivity.clusterIdForSystem(w.system) == clusterId,
    description: 'all known markets',
  );
}

/// Returns the best deals for the given parameters,
/// sorted by profit per second, with most profitable first.
Iterable<CostedDeal> findDealsFor(
  MarketPriceSnapshot marketPrices,
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  MarketScan scan, {
  required WaypointSymbol startSymbol,
  required int fuelCapacity,
  required int cargoCapacity,
  required int shipSpeed,
  required int maxTotalOutlay,
  List<SellOpp>? extraSellOpps,
  bool Function(Deal deal)? filter,
  int minProfitPerSecond = 0,
}) {
  logger.detail(
    'Finding deals with '
    'start: $startSymbol, '
    'from scan: ${scan.description}, '
    'max outlay: $maxTotalOutlay, '
    'max units: $cargoCapacity, '
    'fuel capacity: $fuelCapacity, '
    'ship speed: $shipSpeed',
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
    logger.info('No deals $withinRange.');
    return [];
  }

  // Computing the median price currently requires walking all prices,
  // do do it once and cache it for each call to costOutDeal.
  final costPerFuelUnit = marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ??
      config.defaultFuelCost;
  final costPerAntimatterUnit =
      marketPrices.medianPurchasePrice(TradeSymbol.ANTIMATTER) ??
          config.defaultAntimatterCost;

  final before = DateTime.timestamp();
  final costedDeals = filtered
      .map(
        (deal) => costOutDeal(
          systemsCache,
          routePlanner,
          ShipSpec(
            cargoCapacity: cargoCapacity,
            fuelCapacity: fuelCapacity,
            speed: shipSpeed,
          ),
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
  final route = planner.planRoute(
    shipSpec,
    start: start,
    end: end,
  );
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
  required int shipSpeed,
  required int fuelCapacity,
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
      ShipSpec(
        fuelCapacity: fuelCapacity,
        speed: shipSpeed,
        cargoCapacity: 0,
      ),
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
  required int shipSpeed,
  required int fuelCapacity,
  required int expectedCreditsPerSecond,
}) {
  final sorted = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: start,
    fuelCapacity: fuelCapacity,
    shipSpeed: shipSpeed,
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
MarketTrip? findBestMarketToSell(
  MarketPriceSnapshot marketPrices,
  MarketListingSnapshot marketListings,
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
}) {
  // Some callers might want to use a round trip cost?
  // e.g. if just trying to empty inventory and return to current location.
  final sorted = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    tradeSymbol,
    start: ship.waypointSymbol,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
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
  final costPerFuelUnit = marketPrices.medianPurchasePrice(
        TradeSymbol.FUEL,
      ) ??
      100;
  final costPerUnitAntimatter = marketPrices.medianPurchasePrice(
        TradeSymbol.ANTIMATTER,
      ) ??
      10000;

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
    final listing = marketListings[trip.price.waypointSymbol];
    if (listing == null) {
      detail('Skipping ${trip.price.waypointSymbol} due to no market data');
      continue;
    }
    if (requireFuelAtDestination && !listing.allowsTradeOf(TradeSymbol.FUEL)) {
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
      info('Selecting ${trip.price.waypointSymbol} earns '
          '${creditsString(extraEarnings)} extra '
          '(including ${creditsString(-extraFuelCost)} for fuel) '
          'over ${approximateDuration(extraTime)} '
          '(${earningsPerSecond.toStringAsFixed(1)}/s)');
      best = trip;
      break;
    } else {
      detail('Skipping ${trip.price.waypointSymbol} earns '
          '${creditsString(extraEarnings)} extra '
          '(${creditsString(-extraFuelCost)} for fuel) '
          'for ${approximateDuration(extraTime)} '
          '($earningsPerSecond/s)');
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
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  MarketPriceSnapshot marketPrices,
  RoutePlanner routePlanner, {
  required WaypointSymbol startSymbol,
  required int maxTotalOutlay,
  required ShipSpec shipSpec,
  bool Function(Deal)? filter,
  List<SellOpp>? extraSellOpps,
  int minProfitPerSecond = 0,
}) {
  final marketScan = scanReachableMarkets(
    systemsCache,
    systemConnectivity,
    marketPrices,
    startSystem: startSymbol.system,
  );
  return findDealsFor(
    marketPrices,
    systemsCache,
    routePlanner,
    marketScan,
    maxTotalOutlay: maxTotalOutlay,
    extraSellOpps: extraSellOpps,
    filter: filter,
    startSymbol: startSymbol,
    fuelCapacity: shipSpec.fuelCapacity,
    cargoCapacity: shipSpec.cargoCapacity,
    shipSpeed: shipSpec.speed,
    minProfitPerSecond: minProfitPerSecond,
  );
}
