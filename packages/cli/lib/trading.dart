import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/jump_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/printing.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Record of a possible arbitrage opportunity.
// This should also include expected cost of fuel and cost of time.
@immutable
class Deal {
  /// Create a new deal.
  const Deal({
    required this.sourceSymbol,
    required this.destinationSymbol,
    required this.tradeSymbol,
    required this.purchasePrice,
    required this.sellPrice,
    this.maxUnits,
    this.contractId,
  });

  /// Create a deal from JSON.
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      sourceSymbol: json['sourceSymbol'] as String,
      destinationSymbol: json['destinationSymbol'] as String,
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
      maxUnits: json['maxUnits'] as int?,
      contractId: json['contractId'] as String?,
    );
  }

  /// The trade symbol that we're selling.
  final TradeSymbol tradeSymbol;

  /// The symbol of the market we're buying from.
  final String sourceSymbol;

  /// The symbol of the market we're selling to.
  final String destinationSymbol;

  /// The price we're buying at per unit.
  final int purchasePrice;

  /// The price we're selling at per unit.
  final int sellPrice;
  // Also should take fuel costs into account.
  // And possibly time?

  /// The maximum number of units we can trade in this deal.
  /// This is only used for contract deliveries.  Null means unlimited.
  final int? maxUnits;

  /// The id of the contract this deal is a part of.
  /// Contract deals are very similar to arbitrage deals except:
  /// 1. The destination market is predetermined.
  /// 2. Trade volume is predetermined and coordinated across all ships.
  /// 3. Contract deals only pay out on completed contracts, not for individual
  ///    deliveries, thus they are only viable when we have enough capital
  ///    to expect to complete the contract.
  /// 4. Behavior at destinations is different ("fulfill" instead of "sell").
  /// 5. We treat the "sell" price as the total reward of contract divided by
  ///    the number of units of cargo we need to deliver.
  final String? contractId;

  // Profit depends on route taken, so this likely does not
  // belong here.
  /// The profit we'll make on this deal per unit.
  int get profit => sellPrice - purchasePrice;

  /// Encode the deal as JSON.
  Map<String, dynamic> toJson() => {
        'sourceSymbol': sourceSymbol,
        'destinationSymbol': destinationSymbol,
        'tradeSymbol': tradeSymbol.toJson(),
        'purchasePrice': purchasePrice,
        'sellPrice': sellPrice,
        'maxUnits': maxUnits,
        'contractId': contractId,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Deal &&
          runtimeType == other.runtimeType &&
          tradeSymbol == other.tradeSymbol &&
          sourceSymbol == other.sourceSymbol &&
          destinationSymbol == other.destinationSymbol &&
          purchasePrice == other.purchasePrice &&
          sellPrice == other.sellPrice &&
          maxUnits == other.maxUnits &&
          contractId == other.contractId;

  @override
  int get hashCode =>
      tradeSymbol.hashCode ^
      sourceSymbol.hashCode ^
      destinationSymbol.hashCode ^
      purchasePrice.hashCode ^
      sellPrice.hashCode ^
      maxUnits.hashCode ^
      contractId.hashCode;
}

/// Describe a [deal] in a human-readable way.
String describeDeal(Deal deal) {
  final sign = deal.profit > 0 ? '+' : '';
  final profitPercent = (deal.profit / deal.purchasePrice) * 100;
  final profitCreditsString = '$sign${creditsString(deal.profit)}'.padLeft(6);
  final profitPercentString = '${profitPercent.toStringAsFixed(0)}%';
  final profitString = '$profitCreditsString ($profitPercentString)';
  final coloredProfitString = deal.profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  return '${deal.tradeSymbol.value.padRight(18)} '
      ' ${deal.sourceSymbol} ${creditsString(deal.purchasePrice).padLeft(6)} '
      '-> '
      '${deal.destinationSymbol} ${creditsString(deal.sellPrice).padLeft(6)} '
      '$coloredProfitString';
}

/// Log proposed [deals] to the console.
void logDeals(List<Deal> deals) {
  final headers = [
    'Symbol'.padRight(18),
    'Source'.padRight(18),
    'Dest'.padRight(18),
    'Profit'.padRight(18),
  ];
  logger.info(headers.join(' '));
  for (final deal in deals) {
    logger.info(describeDeal(deal));
  }
}

/// Describe a [deal] in a human-readable way.
String dealDescription(Deal deal, {int units = 1}) {
  final profitString =
      lightGreen.wrap('+${creditsString(deal.profit * units)}');
  return 'Deal ($profitString): ${deal.tradeSymbol} '
      '${creditsString(deal.purchasePrice)} @ ${deal.sourceSymbol} '
      '-> ${creditsString(deal.sellPrice)} @ ${deal.destinationSymbol} '
      'profit: ${creditsString(deal.profit)} per unit ';
}

/// Log a [deal] to the console.
void logDeal(Ship ship, Deal deal) {
  shipInfo(ship, dealDescription(deal, units: ship.availableSpace));
}

// Not sure where this blongs?
/// Returns a waypoint nearby which trades the good.
/// This is not necessarily the nearest, but could be improved to be.
Future<Waypoint?> nearbyMarketWhichTrades(
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Waypoint start,
  String tradeSymbol, {
  int maxJumps = 1,
}) async {
  if (start.hasMarketplace) {
    final startMarket = await marketCache.marketForSymbol(start.symbol);
    if (startMarket!.allowsTradeOf(tradeSymbol)) {
      return start;
    }
  }
  await for (final waypoint in waypointCache.waypointsInJumpRadius(
    startSystem: start.systemSymbol,
    maxJumps: maxJumps,
  )) {
    final market = await marketCache.marketForSymbol(waypoint.symbol);
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
            ...extraSellOpps.where((o) => o.tradeSymbol == tradeSymbol)
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
        deals.add(
          Deal(
            sourceSymbol: buy.marketSymbol,
            tradeSymbol: TradeSymbol.fromJson(tradeSymbol)!,
            purchasePrice: buy.price,
            destinationSymbol: sell.marketSymbol,
            sellPrice: sell.price,
            maxUnits: sell.maxUnits,
            contractId: sell.contractId,
          ),
        );
      }
    }
  }
  return deals;
}

/// A deal between two markets which considers flight cost and time.
// This could be made immutable with a bit of work.  Currently we edit
// transactions in place.
class CostedDeal {
  /// Create a new CostedDeal.
  CostedDeal({
    required this.deal,
    required this.tradeVolume,
    required List<Transaction> transactions,
    required this.startTime,
    required this.route,
    required this.costPerFuelUnit,
  }) : transactions = List.unmodifiable(transactions);

  /// Create a CostedDeal from JSON.
  factory CostedDeal.fromJson(Map<String, dynamic> json) => CostedDeal(
        deal: Deal.fromJson(json['deal'] as Map<String, dynamic>),
        tradeVolume: json['tradeVolume'] as int,
        startTime: DateTime.parse(json['startTime'] as String),
        route: RoutePlan.fromJson(json['route'] as Map<String, dynamic>),
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        costPerFuelUnit: json['costPerFuelUnit'] as int,
      );

  /// The id of the contract this deal is a part of.
  String? get contractId => deal.contractId;

  /// Whether this deal is a contract deal.
  bool get isContractDeal => deal.contractId != null;

  /// The deal being considered.
  final Deal deal;

  /// The number of units of cargo to trade.  This must be less than or equal to
  /// the Deal.maxUnits (if set) and accounts for the specific cargo hold size
  /// of the ship for which we're costing this deal.
  // TODO(eseidel): Rename to maxUnits?
  final int tradeVolume;

  /// The cost per unit of fuel used for computing expected fuel costs.
  final int costPerFuelUnit;

  /// The units of fuel to travel along the route.
  int get expectedFuelUsed => route.fuelUsed;

  /// The cost of fuel to travel along the route.
  int get expectedFuelCost => (expectedFuelUsed / 100).ceil() * costPerFuelUnit;

  /// The time in seconds to travel between the two markets.
  int get expectedTime => route.duration;

  /// The time at which this deal was started.
  final DateTime startTime;

  /// The route taken to complete this deal.
  final RoutePlan route;

  /// The transactions made as a part of executing this deal.
  // It's possible these should be stored separately and composed in
  // to make a CompletedDeal?
  // That would also remove all the expected* prefixes from fields since
  // there would be no actual to compare against.
  final List<Transaction> transactions;

  /// The symbol of the trade good being traded.
  String get tradeSymbol => deal.tradeSymbol.value;

  /// The expected cost of goods sold, not including fuel.
  int get expectedCostOfGoodsSold => deal.purchasePrice * tradeVolume;

  /// The expected non-goods expenses of the deal, including fuel.
  int get expectedOperationalExpenses => expectedFuelCost;

  /// The total upfront cost of the deal, including fuel.
  int get expectedCosts => deal.purchasePrice * tradeVolume + expectedFuelCost;

  /// The total income of the deal, including fuel.
  int get expectedRevenue => deal.sellPrice * tradeVolume;

  /// Max we would spend per unit and still expect to break even.
  int get maxPurchaseUnitPrice =>
      (expectedRevenue - expectedOperationalExpenses) ~/ tradeVolume;

  /// The total profit of the deal, including fuel.
  int get expectedProfit => deal.profit * tradeVolume - expectedFuelCost;

  /// The profit per second of the deal.
  int get expectedProfitPerSecond {
    if (expectedTime < 1) {
      return expectedProfit;
    }
    return expectedProfit ~/ expectedTime;
  }

  /// The actual time taken to complete the deal.
  Duration get actualTime => transactions.last.timestamp.difference(startTime);

  /// The actual revenue of the deal.
  int get actualRevenue {
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.SELL)
        .fold(0, (a, b) => a + b.creditChange);
  }

  /// The actual cost of goods sold.
  int get actualCostOfGoodsSold {
    // TODO(eseidel): This only works when transactions does not include fuel.
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.PURCHASE)
        .where((t) => t.tradeSymbol != TradeSymbol.FUEL.value)
        .fold(0, (a, b) => a + -b.creditChange);
  }

  /// The actual operational expenses of the deal.
  int get actualOperationalExpenses {
    // TODO(eseidel): This only works when tradeSymbol != TradeSymbol.FUEL
    return transactions
        .where((t) => t.tradeType == MarketTransactionTypeEnum.PURCHASE)
        .where((t) => t.tradeSymbol == TradeSymbol.FUEL.value)
        .fold(0, (a, b) => a + -b.creditChange);
  }

  /// The actual profit of the deal.
  int get actualProfit => actualRevenue - actualCostOfGoodsSold;

  /// The actual profit per second of the deal.
  int get actualProfitPerSecond {
    final actualSeconds = actualTime.inSeconds;
    if (actualSeconds == 0) {
      return actualProfit;
    }
    return actualProfit ~/ actualSeconds;
  }

  /// Convert this CostedDeal to JSON.
  Map<String, dynamic> toJson() => {
        'deal': deal.toJson(),
        'expectedFuelCost': expectedFuelCost,
        'tradeVolume': tradeVolume,
        'expectedTime': expectedTime,
        'contractId': contractId,
        'transactions': transactions.map((e) => e.toJson()).toList(),
        'startTime': startTime.toUtc().toIso8601String(),
        'route': route.toJson(),
        'costPerFuelUnit': costPerFuelUnit,
      };

  /// Return a new CostedDeal with the given transactions added.
  CostedDeal byAddingTransactions(List<Transaction> transactions) {
    return CostedDeal(
      deal: deal,
      tradeVolume: tradeVolume,
      transactions: [...this.transactions, ...transactions],
      startTime: startTime,
      route: route,
      costPerFuelUnit: costPerFuelUnit,
    );
  }
}

/// Returns a string describing the given CostedDeal
String describeCostedDeal(CostedDeal costedDeal) {
  const c = creditsString;
  final deal = costedDeal.deal;
  final sign = deal.profit > 0 ? '+' : '';
  final profitPercent = (deal.profit / deal.purchasePrice) * 100;
  final profitCreditsString = '$sign${c(deal.profit)}'.padLeft(8);
  final profitPercentString =
      '(${profitPercent.toStringAsFixed(0)}%)'.padLeft(5);
  final profitString = '$profitCreditsString $profitPercentString';
  final coloredProfitString = deal.profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  final timeString = '${costedDeal.expectedTime}s '
      '${c(costedDeal.expectedProfitPerSecond)}/s';
  final tradeSymbol = deal.tradeSymbol.value;
  final name =
      costedDeal.isContractDeal ? '$tradeSymbol (contract)' : tradeSymbol;
  return '${name.padRight(25)} '
      ' ${deal.sourceSymbol.padRight(14)} ${c(deal.purchasePrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol.padRight(14)} ${c(deal.sellPrice).padLeft(8)} '
      '$coloredProfitString $timeString ${c(costedDeal.expectedCosts)}';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache,
  Deal deal, {
  required int cargoSize,
  required int shipSpeed,
  required String shipWaypointSymbol,
  required int shipFuelCapacity,
  required int costPerFuelUnit,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final route = planRouteThrough(
    systemsCache,
    systemConnectivity,
    jumpCache,
    [shipWaypointSymbol, deal.sourceSymbol, deal.destinationSymbol],
    fuelCapacity: shipFuelCapacity,
    shipSpeed: shipSpeed,
  );

  if (route == null) {
    throw Exception('No route found for $deal');
  }

  return CostedDeal(
    deal: deal,
    tradeVolume:
        deal.maxUnits != null ? min(deal.maxUnits!, cargoSize) : cargoSize,
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
  required String systemSymbol,
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
  );
}

CostedDeal? _filterDealsAndLog(
  Iterable<CostedDeal> costedDeals, {
  required int maxJumps,
  required int maxTotalOutlay,
  required String systemSymbol,
  bool Function(CostedDeal deal)? filter,
}) {
  final filtered = filter != null ? costedDeals.where(filter) : costedDeals;

  final withinRange = 'within $maxJumps of $systemSymbol';
  if (filtered.isEmpty) {
    logger.info('No deals $withinRange.');
    return null;
  }
  final affordable = filtered.where((d) => d.expectedCosts < maxTotalOutlay);
  if (affordable.isEmpty) {
    logger.info('No deals < ${creditsString(maxTotalOutlay)} $withinRange.');
    return null;
  }
  final sortedDeals =
      affordable.sortedBy<num>((e) => e.expectedProfitPerSecond);

  logger.info('Top 5 deals $withinRange:');
  for (final deal in sortedDeals.reversed.take(5).toList().reversed) {
    logger.info(describeCostedDeal(deal));
  }

  final profitable = sortedDeals.where((d) => d.expectedProfitPerSecond > 0);
  if (profitable.isEmpty) {
    logger.info('No profitable deals $withinRange.');
    return null;
  }
  return profitable.last;
}

/// Returns the best deal for the given parameters.
Future<CostedDeal?> findDealFor(
  MarketPrices marketPrices,
  SystemsCache systemsCache,
  SystemConnectivity systemConnectivity,
  JumpCache jumpCache,
  MarketScan scan, {
  required String startSymbol,
  required int fuelCapacity,
  required int cargoCapacity,
  required int shipSpeed,
  required int maxJumps,
  required int maxTotalOutlay,
  List<SellOpp>? extraSellOpps,
  bool Function(CostedDeal deal)? filter,
}) async {
  logger.detail(
    'Finding deals with '
    'start: $startSymbol, '
    'max jumps: $maxJumps, '
    'max outlay: $maxTotalOutlay, '
    'max units: $cargoCapacity, '
    'fuel capacity: $fuelCapacity, '
    'ship speed: $shipSpeed',
  );

  final deals = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);
  logger.detail('Found ${deals.length} potential deals.');

  final before = DateTime.now();
  final costedDeals = deals
      .map(
        (deal) => costOutDeal(
          shipSpeed: shipSpeed,
          systemsCache,
          systemConnectivity,
          jumpCache,
          deal,
          cargoSize: cargoCapacity,
          shipWaypointSymbol: startSymbol,
          shipFuelCapacity: fuelCapacity,
          costPerFuelUnit:
              marketPrices.medianPurchasePrice(TradeSymbol.FUEL.value) ?? 100,
        ),
      )
      .toList();
  // toList is used to force resolution of the list before we log.
  final after = DateTime.now();
  final elapsed = after.difference(before);
  logger
      .info('Costed ${deals.length} deals in ${approximateDuration(elapsed)}');
  return _filterDealsAndLog(
    costedDeals,
    maxJumps: maxJumps,
    maxTotalOutlay: maxTotalOutlay,
    systemSymbol: startSymbol,
    filter: filter,
  );
}
