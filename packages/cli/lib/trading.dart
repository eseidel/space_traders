import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/printing.dart';
import 'package:cli/route.dart';
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
  });

  /// Create a deal from JSON.
  factory Deal.fromJson(Map<String, dynamic> json) {
    return Deal(
      sourceSymbol: json['sourceSymbol'] as String,
      destinationSymbol: json['destinationSymbol'] as String,
      tradeSymbol: TradeSymbol.fromJson(json['tradeSymbol'] as String)!,
      purchasePrice: json['purchasePrice'] as int,
      sellPrice: json['sellPrice'] as int,
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
          sellPrice == other.sellPrice;

  @override
  int get hashCode =>
      tradeSymbol.hashCode ^
      sourceSymbol.hashCode ^
      destinationSymbol.hashCode ^
      purchasePrice.hashCode ^
      sellPrice.hashCode;
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
  });

  /// The symbol of the market where the good is bought.
  final String marketSymbol;

  /// The symbol of the good being bought.
  final String tradeSymbol;

  /// The price of the good.
  final int price;
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
List<Deal> buildDealsFromScan(MarketScan scan) {
  final deals = <Deal>[];
  // final fuelPrice = _priceData.medianPurchasePrice(TradeSymbol.FUEL.value);
  for (final tradeSymbol in scan.tradeSymbols) {
    final buys = scan.buyOppsForTradeSymbol(tradeSymbol);
    final sells = scan.sellOppsForTradeSymbol(tradeSymbol);
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
    required this.fuelCost,
    required this.tradeVolume,
    required this.time,
    required List<MarketTransaction> transactions,
  }) : transactions = List.unmodifiable(transactions);

  /// Create a CostedDeal from JSON.
  factory CostedDeal.fromJson(Map<String, dynamic> json) => CostedDeal(
        deal: Deal.fromJson(json['deal'] as Map<String, dynamic>),
        fuelCost: json['fuelCost'] as int,
        tradeVolume: json['tradeVolume'] as int,
        time: json['time'] as int,
        transactions: (json['transactions'] as List<dynamic>)
            .map((e) => MarketTransaction.fromJson(e as Map<String, dynamic>)!)
            .toList(),
      );

  /// The deal being considered.
  final Deal deal;

  /// The units of fuel to travel between the two markets.
  final int fuelCost;

  /// The number of units of cargo to trade.
  final int tradeVolume;

  /// The time in seconds to travel between the two markets.
  final int time;

  /// The tranactions made as a part of executing this deal.
  final List<MarketTransaction> transactions;

  /// The symbol of the trade good being traded.
  String get tradeSymbol => deal.tradeSymbol.value;

  /// The expected cost of goods sold, not including fuel.
  int get expectedCostOfGoodsSold => deal.purchasePrice * tradeVolume;

  /// The expected non-goods expenses of the deal, including fuel.
  int get expectedOperationalExpenses => fuelCost;

  /// The total upfront cost of the deal, including fuel.
  int get expectedCosts => deal.purchasePrice * tradeVolume + fuelCost;

  /// The total income of the deal, including fuel.
  int get expectedRevenue => deal.sellPrice * tradeVolume;

  /// Max we would spend per unit and still expect to break even.
  int get maxPurchaseUnitPrice =>
      (expectedRevenue - expectedOperationalExpenses) ~/ tradeVolume;

  /// The total profit of the deal, including fuel.
  int get profit => deal.profit * tradeVolume - fuelCost;

  /// The profit per second of the deal.
  int get profitPerSecond => profit ~/ time;

  /// Convert this CostedDeal to JSON.
  Map<String, dynamic> toJson() => {
        'deal': deal.toJson(),
        'fuelCost': fuelCost,
        'tradeVolume': tradeVolume,
        'time': time,
        'transactions': transactions.map((e) => e.toJson()).toList(),
      };

  /// Copy this CostedDeal with the given fields replaced.
  CostedDeal copyWith({
    Deal? deal,
    int? fuelCost,
    int? tradeVolume,
    int? time,
    List<MarketTransaction>? transactions,
  }) {
    return CostedDeal(
      deal: deal ?? this.deal,
      fuelCost: fuelCost ?? this.fuelCost,
      tradeVolume: tradeVolume ?? this.tradeVolume,
      time: time ?? this.time,
      transactions: transactions ?? this.transactions,
    );
  }
}

/// Returns a string describing the given CostedDeal
String describeCostedDeal(CostedDeal costedDeal) {
  final deal = costedDeal.deal;
  final sign = deal.profit > 0 ? '+' : '';
  final profitPercent = (deal.profit / deal.purchasePrice) * 100;
  final profitCreditsString = '$sign${creditsString(deal.profit)}'.padLeft(8);
  final profitPercentString =
      '(${profitPercent.toStringAsFixed(0)}%)'.padLeft(5);
  final profitString = '$profitCreditsString $profitPercentString';
  final coloredProfitString = deal.profit > 0
      ? lightGreen.wrap(profitString)
      : lightRed.wrap(profitString);
  final timeString = '${costedDeal.time}s ${costedDeal.profitPerSecond}c/s';
  return '${deal.tradeSymbol.value.padRight(25)} '
      ' ${deal.sourceSymbol} ${creditsString(deal.purchasePrice).padLeft(8)} '
      '-> '
      '${deal.destinationSymbol} ${creditsString(deal.sellPrice).padLeft(8)} '
      '$coloredProfitString $timeString ${costedDeal.expectedCosts}c';
}

/// Returns a CostedDeal for a given deal.
CostedDeal costOutDeal(
  SystemsCache systemsCache,
  Deal deal, {
  required int cargoSize,
  required int shipSpeed,
  ShipNavFlightMode flightMode = ShipNavFlightMode.CRUISE,
}) {
  final source = systemsCache.waypointFromSymbol(deal.sourceSymbol);
  final destination = systemsCache.waypointFromSymbol(deal.destinationSymbol);
  return CostedDeal(
    deal: deal,
    fuelCost: fuelUsedBetween(
      systemsCache,
      source,
      destination,
    ),
    time: flightTimeBetween(
      systemsCache,
      source,
      destination,
      flightMode: flightMode,
      shipSpeed: shipSpeed,
    ),
    tradeVolume: cargoSize,
    transactions: [],
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
  required int maxOutlay,
  required int availableSpace,
  bool Function(CostedDeal deal)? filter,
}) async {
  final markets = await marketCache
      .marketsInJumpRadius(
        startSystem: ship.nav.systemSymbol,
        maxJumps: maxJumps,
      )
      .toList();
  final scan = MarketScan.fromMarkets(marketPrices, markets);
  final deals = buildDealsFromScan(scan);

  final costedDeals = deals
      .map(
        (d) => costOutDeal(
          systemsCache,
          d,
          cargoSize: availableSpace,
          shipSpeed: ship.engine.speed,
        ),
      )
      .toList();

  final filtered =
      filter != null ? costedDeals.where(filter).toList() : costedDeals;

  if (filtered.isEmpty) {
    logger.info('No deals found.');
    return null;
  }
  final affordable =
      filtered.where((d) => d.expectedCosts < maxOutlay).toList();
  if (affordable.isEmpty) {
    logger.info('No deals found under $maxOutlay credits.');
    return null;
  }
  final sortedDeals = affordable
      .sorted((a, b) => a.profitPerSecond.compareTo(b.profitPerSecond));

  logger.detail('Considering deals:');
  for (final deal in sortedDeals) {
    logger.detail(describeCostedDeal(deal));
  }
  return sortedDeals.last;
}
