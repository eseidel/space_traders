import 'dart:math';

import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

// Not sure where this belongs?
/// Returns a waypoint nearby which trades the good.
/// This is not necessarily the nearest, but could be improved to be.
/// Unlike findBestMarketToSell or findBestMarketToBuy, this could find
/// markets we've never visited before (e.g. for emergency fuel purchases
/// or when we're just starting out and don't have a lot of data yet).
// TODO(eseidel): replace with findBestMarketToSell in all places?
Future<Waypoint?> nearbyMarketWhichTrades(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketListingCache marketListings,
  WaypointSymbol startSymbol,
  TradeSymbol tradeSymbol, {
  int maxJumps = 1,
}) async {
  final start = await waypointCache.waypoint(startSymbol);
  if (start.hasMarketplace) {
    final startMarket =
        marketListings.marketListingForSymbol(start.waypointSymbol);
    if (startMarket!.allowsTradeOf(tradeSymbol)) {
      return start;
    }
  }
  await for (final waypoint in waypointCache.waypointsInJumpRadius(
    startSystem: start.systemSymbolObject,
    maxJumps: maxJumps,
  )) {
    final market =
        marketListings.marketListingForSymbol(waypoint.waypointSymbol);
    if (market != null && market.allowsTradeOf(tradeSymbol)) {
      return waypoint;
    }
  }
  return null;
}

/// Builds a list of deals found from the provided MarketScan.
/// If overrideBuyOpps or overrideSellOpps are provided, they will be used
/// instead of the ones from the scan.  This is useful for when you want
/// to build a Deal where you already know where it must be bought or sold.
/// Similarly if overrideTradeSymbols is provided, it will be used instead
/// of the ones from the scan.
List<Deal> buildDealsFromScan(
  MarketScan scan, {
  List<SellOpp>? extraSellOpps,
}) {
  final deals = <Deal>[];
  // final fuelPrice = _priceData.medianPurchasePrice(TradeSymbol.FUEL.value);
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
        if (buy.marketSymbol == sell.marketSymbol) {
          continue;
        }
        final profit = sell.price - buy.price;
        if (profit <= 0) {
          continue;
        }
        deals.add(Deal.fromOpps(buy, sell));
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

/// Logic for extrapolating from a CostedDeal
extension CostedDealPrediction on CostedDeal {
  /// expectedUnits uses cargoSize instead of maxUnitsToBuy when computing
  /// pricing to avoid having contracts never finish due to only needing one
  /// more unit yet that unit not being worth carrying in an otherwise empty
  /// ship.
  int get expectedUnits {
    final destinationPrice = deal.destinationPrice;
    // Contract deal
    if (destinationPrice == null) {
      return cargoSize;
    }
    return min(
      cargoSize,
      profitableVolumeBetween(
        deal.sourcePrice,
        destinationPrice,
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
      deal.sourcePrice.totalPurchasePriceFor(expectedUnits);

  /// The expected non-goods expenses of the deal, including fuel.
  int get expectedOperationalExpenses => expectedFuelCost;

  /// The total upfront cost of the deal, including fuel.
  int get expectedCosts =>
      expectedCostOfGoodsSold + expectedOperationalExpenses;

  /// The total income of the deal, including fuel.
  int get expectedRevenue {
    // Contract rewards don't move with market state.
    final contract = deal.contractDelivery;
    if (contract != null) {
      return contract.rewardPerUnit * expectedUnits;
    }
    return deal.destinationPrice!.totalSellPriceFor(expectedUnits);
  }

  /// The expected initial per-unit buy price.
  int get expectedInitialBuyPrice =>
      deal.sourcePrice.predictPurchasePriceForUnit(0);

  /// The expected initial per-unit sell price.
  int get expectedInitialSellPrice {
    final contract = deal.contractDelivery;
    if (contract != null) {
      return contract.rewardPerUnit;
    }
    return deal.destinationPrice!.predictSellPriceForUnit(0);
  }

  /// Max we would spend per unit and still expect to break even.
  int get maxPurchaseUnitPrice =>
      (expectedRevenue - expectedOperationalExpenses) ~/ expectedUnits;

  // This does not acount for any expected profit.
  /// The expected per-unit purchase price for the next lot of units.
  /// For each additional unit (or batch of) we buy, we expect to:
  /// - spend more to buy it (prices go up at source market)
  /// - less to transport it (opex is amortized over more units)
  /// - and sell it for less (prices go down at destination market)
  /// This function answers the question "what's the max we would pay
  /// perUnit for this next lot of unit and still expect to profit".
  // int maxPurchaseUnitPrice({required int existingUnits,
  //      required int lotSize}) {
  //   // Contract deals are easy, "sell" prices dont change.
  //   // perUnitRewards - perUnitOpExp = maxPerUnitPurchasePrice
  //   final destinationPrice = deal.destinationPrice;
  //   if (destinationPrice == null) {
  //     return (expectedRevenue - expectedOperationalExpenses) ~/ expectedUnits;
  //   }
  //   // Taking lotSize into account, we end up with a smaller max purchase price
  //   // for the first few units (as the fuel costs are spread over few units)
  //   // which gets higher as we buy more units (as the fuel costs are spread
  //   // over more units) and then lower again as we buy more units (as the
  //   // destination price drops).

  //   // This should get a range value instead?
  //   final expectedSellValue =
  //       destinationPrice.predictSellPriceForUnit(existingUnits + 1)
  // }

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
      return deal.sourcePrice.purchasePrice;
    }
    return deal.sourcePrice.predictPurchasePriceForUnit(unitsPurchased + 1);
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
    final maxUnits = deal.sourcePrice.predictUnitsPurchasableFor(goodsBudget);
    if (maxUnits < cargoSize) {
      return CostedDeal(
        deal: deal,
        cargoSize: maxUnits,
        transactions: transactions,
        startTime: startTime,
        route: route,
        costPerFuelUnit: costPerFuelUnit,
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
      ' ${deal.sourceSymbol.waypoint.padRight(14)} '
      // This could use the average expected purchase/sell price across the
      // whole deal volume.
      '${c(costedDeal.expectedInitialBuyPrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol.waypoint.padRight(14)} '
      '${c(costedDeal.expectedInitialSellPrice).padLeft(8)} '
      '$coloredProfitString $timeString '
      '${c(costedDeal.expectedCosts).padLeft(8)}';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  SystemsCache systemsCache,
  RoutePlanner routePlanner,
  Deal deal, {
  required int cargoSize,
  required int shipSpeed,
  required WaypointSymbol shipWaypointSymbol,
  required int shipFuelCapacity,
  required int costPerFuelUnit,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final route = planRouteThrough(
    systemsCache,
    routePlanner,
    [shipWaypointSymbol, deal.sourceSymbol, deal.destinationSymbol],
    fuelCapacity: shipFuelCapacity,
    shipSpeed: shipSpeed,
  );

  if (route == null) {
    throw Exception('No route found for $deal');
  }

  return CostedDeal(
    deal: deal,
    cargoSize: cargoSize,
    transactions: [],
    startTime: DateTime.timestamp(),
    route: route,
    costPerFuelUnit: costPerFuelUnit,
  );
}

/// Builds a MarketScan from a starting system outwards limiting to
/// maxJumps and maxWaypoints.
MarketScan scanNearbyMarkets(
  SystemsCache systemsCache,
  MarketPrices marketPrices, {
  required SystemSymbol systemSymbol,
  required int maxJumps,
  required int maxWaypoints,
}) {
  final allowedWaypoints = systemsCache
      .waypointSymbolsInJumpRadius(
        startSystem: systemSymbol,
        maxJumps: maxJumps,
      )
      .take(maxWaypoints)
      .toSet();
  logger.detail('Considering ${allowedWaypoints.length} waypoints');

  return MarketScan.fromMarketPrices(
    marketPrices,
    waypointFilter: allowedWaypoints.contains,
    description:
        '$maxJumps jumps of $systemSymbol (limit $maxWaypoints waypoints)',
  );
}

/// Returns the best deals for the given parameters,
/// sorted by profit per second, with most profitable first.
Iterable<CostedDeal> findDealsFor(
  MarketPrices marketPrices,
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

  final deals = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);
  logger.detail('Found ${deals.length} potential deals.');

  final filtered = filter != null ? deals.where(filter) : deals;

  final withinRange = 'within ${scan.description}';
  if (filtered.isEmpty) {
    logger.info('No deals $withinRange.');
    return [];
  }

  final before = DateTime.now();
  final costedDeals = filtered
      .map(
        (deal) => costOutDeal(
          shipSpeed: shipSpeed,
          systemsCache,
          routePlanner,
          deal,
          cargoSize: cargoCapacity,
          shipWaypointSymbol: startSymbol,
          shipFuelCapacity: fuelCapacity,
          costPerFuelUnit:
              marketPrices.medianPurchasePrice(TradeSymbol.FUEL) ?? 100,
        ),
      )
      .toList();

  // toList is used to force resolution of the list before we log.
  final after = DateTime.now();
  final elapsed = after.difference(before);
  // This should be 300ms or less.
  if (elapsed > const Duration(seconds: 1)) {
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
      .where((d) => d.expectedProfitPerSecond > 0);
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
  Ship ship,
  RoutePlanner planner,
  T price,
  WaypointSymbol start,
  WaypointSymbol end,
) {
  final route = planner.planRoute(
    start: start,
    end: end,
    fuelCapacity: ship.fuel.capacity,
    shipSpeed: ship.engine.speed,
  );
  if (route == null) {
    return null;
  }
  return CostedTrip(route: route, price: price);
}

/// Returns a list of MarketTrips for markets which trade the given symbol
/// sorted by distance.
List<MarketTrip> marketsTradingSortedByDistance(
  MarketPrices marketPrices,
  RoutePlanner routePlanner,
  Ship ship,
  TradeSymbol tradeSymbol,
) {
  final prices = marketPrices.pricesFor(tradeSymbol).toList();
  if (prices.isEmpty) {
    return [];
  }
  final start = ship.waypointSymbol;

  // If there are a lot of prices we could cut down the search space by only
  // looking at prices at or below median?
  // final medianPrice = marketPrices.medianPurchasePrice(tradeSymbol)!;
  // Find the closest 10 prices which are median or below.
  // final medianOrBelow = prices.where((e) => e.purchasePrice <= medianPrice);

  final costed = <MarketTrip>[];
  for (final price in prices) {
    final end = price.waypointSymbol;
    final trip = costTrip<MarketPrice>(ship, routePlanner, price, start, end);
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
  MarketPrices marketPrices,
  RoutePlanner routePlanner,
  Ship ship,
  TradeSymbol tradeSymbol, {
  required int expectedCreditsPerSecond,
}) {
  final sorted = marketsTradingSortedByDistance(
    marketPrices,
    routePlanner,
    ship,
    tradeSymbol,
  );
  if (sorted.isEmpty) {
    return null;
  }
  final nearest = sorted.first;
  var best = nearest;
  // Pick any one further that saves more than expectedCreditsPerSecond
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

/// Find the best market to sell a given item to.
/// expectedCreditsPerSecond is the time value of money (e.g. 7c/s)
/// used for evaluating the trade-off between "closest" vs. "cheapest".
/// This does not account for fuel costs.
MarketTrip? findBestMarketToSell(
  MarketPrices marketPrices,
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
    ship,
    tradeSymbol,
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
  var best = nearest;
  // Pick any one further that earns more than expectedCreditsPerSecond
  for (final trip in sorted.sublist(1)) {
    final priceDiff = trip.price.sellPrice - nearest.price.sellPrice;
    var extraEarnings = priceDiff * unitsToSell;
    final extraTime =
        applyMin(trip.route.duration) - applyMin(nearest.route.duration);

    final costPerFuelUnit = marketPrices.recentPurchasePrice(
      TradeSymbol.FUEL,
      marketSymbol: trip.route.endSymbol,
    );
    final extraFuel = (trip.route.fuelUsed - nearest.route.fuelUsed) * 2;
    final extraFuelCost = costPerFuelUnit != null
        ? costPerFuelUnit * (extraFuel / 100).ceil()
        : 0;
    if (costPerFuelUnit != null) {
      extraEarnings -= extraFuelCost;
    } else if (costPerFuelUnit == null && requireFuelAtDestination) {
      detail('Skipping ${trip.price.waypointSymbol} due to unknown fuel cost');
      continue;
    }

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
