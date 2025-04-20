// This doesn't really belong in types?

import 'dart:math';

import 'package:types/types.dart';

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

double _expectedPercentageChangeByVolume(int tradeVolume) {
  if (tradeVolume < 10) {
    return 1;
  }
  if (tradeVolume < 25) {
    return 0.50;
  }
  if (tradeVolume < 50) {
    return 0.30;
  }
  if (tradeVolume < 100) {
    return 0.10;
  }
  return 0;
}

/// Predict the next price based on the current price and the trade volume.
int expectedPriceMovement({
  required int currentPrice,
  required int tradeVolume,
  required int units,
  // required int medianPrice,
  required MarketTransactionTypeEnum action,
}) {
  // I'm confident that price movements are quadratic in nature.
  // When I've attempted to fit the curve across multiple repeated buys,
  // they've fit very well to a quadratic curve.
  // Including buying units below the set price *decreasing* the price.
  // However I don't know how to turn that into a function to predict the
  // next price, especially across multiple different markets and trade goods.
  // These price changes most notably affect "shallow" markets, where the
  // trade volume is low.
  // I don't have good data for tradeVolume = 1, it likely moves faster?
  final sign = action == MarketTransactionTypeEnum.PURCHASE ? 1 : -1;
  final percentChange = _expectedPercentageChangeByVolume(tradeVolume);
  return sign * (percentChange * currentPrice).round();
}

/// Add prediction capabilities to MarketPrice
extension MarketPricePredications on MarketPrice {
  /// Predict the price of buying the Nth unit of this good.
  /// Unit is a 0-based index of the unit being purchased.
  int predictPurchasePriceForUnit(int unit) {
    var predictedPrice = purchasePrice;
    final batchCount = unit ~/ tradeVolume;
    for (var i = 0; i < batchCount; i++) {
      final expectedMovement = expectedPriceMovement(
        currentPrice: predictedPrice,
        tradeVolume: tradeVolume,
        units: unit,
        action: MarketTransactionTypeEnum.PURCHASE,
      );
      predictedPrice += expectedMovement;
    }
    return predictedPrice;
  }

  /// Predict the number of units that can be purchased for [maxSpend].
  int predictUnitsPurchasableFor({
    required int maxSpend,
    required int maxUnits,
  }) {
    var units = 0;
    var totalCost = 0;
    // This is not efficient, but works for now.
    while (totalCost < maxSpend) {
      if (units >= maxUnits) {
        break;
      }
      totalCost += predictPurchasePriceForUnit(units);
      units++;
    }
    return units;
  }

  /// Predict the price of buying the Nth unit of this good.
  /// Unit is a 0-based index of the unit being purchased.
  int predictSellPriceForUnit(int unit) {
    var predictedPrice = sellPrice;
    final batchCount = unit ~/ tradeVolume;
    for (var i = 0; i < batchCount; i++) {
      final expectedMovement = expectedPriceMovement(
        currentPrice: predictedPrice,
        tradeVolume: tradeVolume,
        units: unit,
        action: MarketTransactionTypeEnum.SELL,
      );
      predictedPrice += expectedMovement;
    }
    return predictedPrice;
  }
}

/// Logic for predicting the next price for a market.
extension MarketPricePredictions on MarketPrice {
  /// Predict the total price of buying [units] of this good.
  int totalPurchasePriceFor(int units) {
    var totalPrice = 0;
    for (var i = 0; i < units; i++) {
      totalPrice += predictPurchasePriceForUnit(i);
    }
    return totalPrice;
  }

  /// Predict the total price of buying [units] of this good.
  int totalSellPriceFor(int units) {
    var totalPrice = 0;
    for (var i = 0; i < units; i++) {
      totalPrice += predictSellPriceForUnit(i);
    }
    return totalPrice;
  }
}
