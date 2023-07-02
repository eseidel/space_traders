import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
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
          maxUnits == other.maxUnits;

  @override
  int get hashCode =>
      tradeSymbol.hashCode ^
      sourceSymbol.hashCode ^
      destinationSymbol.hashCode ^
      purchasePrice.hashCode ^
      sellPrice.hashCode ^
      maxUnits.hashCode;
}

int _percentileForTradeType(ExchangeType tradeType) {
  switch (tradeType) {
    case ExchangeType.exchange:
      return 50;
    case ExchangeType.imports:
      return 25;
    case ExchangeType.exports:
      return 75;
  }
}

/// Estimate the current sell price of [tradeSymbol] at [market].
int? estimateSellPrice(
  MarketPrices marketPrices,
  Market market,
  String tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods = market.marketTradeGood(tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.sellPrice;
  }

  final recentSellPrice = marketPrices.recentSellPrice(
    marketSymbol: market.symbol,
    tradeSymbol: tradeSymbol,
  );
  if (recentSellPrice != null) {
    return recentSellPrice;
  }
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    return null;
  }
  final percentile = _percentileForTradeType(tradeType);
  return marketPrices.sellPriceAtPercentile(tradeSymbol, percentile);
}

/// Estimate the current purchase price of [tradeSymbol] at [market].
int? estimatePurchasePrice(
  MarketPrices marketPrices,
  Market market,
  String tradeSymbol,
) {
  // This case would only be needed if we have a ship at the market, but somehow
  // failed to record price data in our price db.
  final maybeGoods = market.marketTradeGood(tradeSymbol);
  if (maybeGoods != null) {
    return maybeGoods.purchasePrice;
  }
  final recentPurchasePrice = marketPrices.recentPurchasePrice(
    marketSymbol: market.symbol,
    tradeSymbol: tradeSymbol,
  );
  if (recentPurchasePrice != null) {
    return recentPurchasePrice;
  }
  final tradeType = market.exchangeType(tradeSymbol);
  if (tradeType == null) {
    return null;
  }
  final percentile = _percentileForTradeType(tradeType);
  return marketPrices.purchasePriceAtPercentile(tradeSymbol, percentile);
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

/// A potential purchase opportunity.
@immutable
class BuyOpp {
  /// Create a new BuyOpp.
  const BuyOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
  });

  /// The symbol of the market where the good is sold.
  final String marketSymbol;

  /// The symbol of the good being sold.
  final String tradeSymbol;

  /// The price of the good.
  final int price;
}

/// A potential sale opportunity.  Only public for testing.
@immutable
class SellOpp {
  /// Create a new SellOpp.
  const SellOpp({
    required this.marketSymbol,
    required this.tradeSymbol,
    required this.price,
    this.isContractDelivery = false,
    this.maxUnits,
  });

  /// The symbol of the market where the good is bought.
  final String marketSymbol;

  /// The symbol of the good being bought.
  final String tradeSymbol;

  /// The price of the good.
  final int price;

  /// Whether this is a contract delivery.
  final bool isContractDelivery;

  /// The maximum number of units we can sell.
  /// This is only used for contract deliveries towards the very end of
  /// a contract.
  final int? maxUnits;
}

class _MarketScanBuilder {
  _MarketScanBuilder(MarketPrices marketPrices, {required this.topLimit})
      : _marketPrices = marketPrices;

  /// How many deals to keep track of per trade symbol.
  final int topLimit;
  final Map<String, List<BuyOpp>> buyOpps = {};
  final Map<String, List<SellOpp>> sellOpps = {};

  final MarketPrices _marketPrices;

  /// Record potential deals from the given market.
  void visitMarket(Market market) {
    for (final tradeSymbol in market.allTradeSymbols) {
      // See if the price data we have for this trade symbol
      // are in the top/bottom we've seen, if so, record them.
      final buyPrice =
          estimatePurchasePrice(_marketPrices, market, tradeSymbol.value);
      if (buyPrice == null) {
        // If we don't have buy data we won't have sell data either.
        continue;
      }
      final buy = BuyOpp(
        marketSymbol: market.symbol,
        tradeSymbol: tradeSymbol.value,
        price: buyPrice,
      );
      final buys = buyOpps[tradeSymbol.value] ?? [];
      // No clue what it wants me to cascade here?
      // ignore: cascade_invocations
      buys
        ..add(buy)
        ..sort((a, b) => a.price.compareTo(b.price));
      if (buys.length > topLimit) {
        buys.removeLast();
      }
      buyOpps[tradeSymbol.value] = buys;
      final sell = SellOpp(
        marketSymbol: market.symbol,
        tradeSymbol: tradeSymbol.value,
        price: estimateSellPrice(_marketPrices, market, tradeSymbol.value)!,
      );
      final sells = sellOpps[tradeSymbol.value] ?? [];
      // No clue what it wants me to cascade here?
      // ignore: cascade_invocations
      sells
        ..add(sell)
        ..sort((a, b) => a.price.compareTo(b.price));
      if (sells.length > topLimit) {
        sells.removeLast();
      }
      sellOpps[tradeSymbol.value] = sells;
    }
  }
}

/// Represents a collection of buy and sell opportunities for a given set
/// of markets.
class MarketScan {
  MarketScan._({
    required Map<String, List<BuyOpp>> buyOpps,
    required Map<String, List<SellOpp>> sellOpps,
  })  : _buyOpps = Map.unmodifiable(buyOpps),
        _sellOpps = Map.unmodifiable(sellOpps);

  /// Given a set of markets, will collect the top N buy and sell opportunities
  /// for each trade symbol.
  factory MarketScan.fromMarkets(
    MarketPrices marketPrices,
    Iterable<Market> markets,
  ) {
    final builder = _MarketScanBuilder(marketPrices, topLimit: 5);
    for (final market in markets) {
      builder.visitMarket(market);
    }
    return MarketScan._(buyOpps: builder.buyOpps, sellOpps: builder.sellOpps);
  }

  final Map<String, List<BuyOpp>> _buyOpps;
  final Map<String, List<SellOpp>> _sellOpps;

  /// The trade symbols for which we found opportunities.
  List<String> get tradeSymbols => _buyOpps.keys.toList();

  /// Lookup the buy opportunities for the given trade symbol.
  List<BuyOpp> buyOppsForTradeSymbol(String tradeSymbol) =>
      _buyOpps[tradeSymbol] ?? [];

  /// Lookup the sell opportunities for the given trade symbol.
  List<SellOpp> sellOppsForTradeSymbol(String tradeSymbol) =>
      _sellOpps[tradeSymbol] ?? [];
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
    final sells =
        extraSellOpps != null ? [...scanSells, ...extraSellOpps] : scanSells;
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
    this.contractId,
  }) : transactions = List.unmodifiable(transactions);

  /// Create a CostedDeal from JSON.
  factory CostedDeal.fromJson(Map<String, dynamic> json) => CostedDeal(
        deal: Deal.fromJson(json['deal'] as Map<String, dynamic>),
        tradeVolume: json['tradeVolume'] as int,
        contractId: json['contractId'] as String?,
        startTime: json['startTime'] == null
            ? null
            : DateTime.parse(json['startTime'] as String),
        route: RoutePlan.fromJson(json['route'] as Map<String, dynamic>),
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        costPerFuelUnit: json['costPerFuelUnit'] as int,
      );

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

  /// Whether this deal is a contract deal.
  bool get isContractDeal => contractId != null;

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
  final DateTime? startTime;

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
  Duration get actualTime {
    // TODO(eseidel): This isn't right for deals where we have to travel
    // to the source location.
    final start = transactions.first.timestamp;
    final end = transactions.last.timestamp;
    return end.difference(start);
  }

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
      return 0;
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
        'startTime': startTime?.toIso8601String(),
        'route': route.toJson(),
        'costPerFuelUnit': costPerFuelUnit,
      };

  /// Copy this CostedDeal with the given fields replaced.
  CostedDeal copyWith({
    Deal? deal,
    int? expectedFuelCost,
    int? tradeVolume,
    int? expectedTime,
    List<Transaction>? transactions,
  }) {
    return CostedDeal(
      deal: deal ?? this.deal,
      tradeVolume: tradeVolume ?? this.tradeVolume,
      transactions: transactions ?? this.transactions,
      startTime: startTime,
      route: route,
      costPerFuelUnit: costPerFuelUnit,
    );
  }

  /// Return a new CostedDeal with the given transactions added.
  CostedDeal byAddingTransactions(List<Transaction> transactions) {
    return copyWith(
      transactions: [...this.transactions, ...transactions],
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
  return '${deal.tradeSymbol.value.padRight(25)} '
      ' ${deal.sourceSymbol} ${c(deal.purchasePrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol} ${c(deal.sellPrice).padLeft(8)} '
      '$coloredProfitString $timeString ${c(costedDeal.expectedCosts)}';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  SystemsCache systemsCache,
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

/// Returns the best deal for the given ship within [maxJumps] of it's
/// current location.
Future<CostedDeal?> findDealFor(
  MarketPrices marketPrices,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  Ship ship, {
  required int maxJumps,
  required int maxTotalOutlay,
  required int availableSpace,
  List<SellOpp>? extraSellOpps,
  bool Function(CostedDeal deal)? filter,
}) async {
  final systemSymbol = ship.nav.systemSymbol;
  final markets = await marketCache
      .marketsInJumpRadius(
        startSystem: systemSymbol,
        maxJumps: maxJumps,
      )
      .toList();
  final scan = MarketScan.fromMarkets(marketPrices, markets);
  final deals = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);

  final costedDeals = deals.map(
    (deal) => costOutDeal(
      shipSpeed: ship.engine.speed,
      systemsCache,
      deal,
      cargoSize: availableSpace,
      shipWaypointSymbol: ship.nav.waypointSymbol,
      shipFuelCapacity: ship.fuel.capacity,
      costPerFuelUnit:
          marketPrices.medianPurchasePrice(TradeSymbol.FUEL.value) ?? 100,
    ),
  );

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

  logger.detail('Considering deals:');
  for (final deal in sortedDeals) {
    logger.detail(describeCostedDeal(deal));
  }

  final profitable = sortedDeals.where((d) => d.expectedProfitPerSecond > 0);
  if (profitable.isEmpty) {
    logger.info('No profitable deals $withinRange.');
    return null;
  }
  return profitable.last;
}
