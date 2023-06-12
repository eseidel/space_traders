import 'dart:math';

import 'package:async/async.dart';
import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/behavior/trading.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/transactions.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

// List<Market> _marketsWithExport(
//   String tradeSymbol,
//   List<Market> markets,
// ) {
//   return markets
//       .where((m) => m.exports.any((e) => e.symbol.value == tradeSymbol))
//       .toList();
// }

// List<Market> _marketsWithExchange(
//   String tradeSymbol,
//   List<Market> markets,
// ) {
//   return markets
//       .where((m) => m.exchange.any((e) => e.symbol.value == tradeSymbol))
//       .toList();
// }

Future<DeliverContract200ResponseData?> _deliverContractGoodsIfPossible(
  Api api,
  Ship ship,
  Contract contract,
  ContractDeliverGood goods,
) async {
  final units = ship.countUnits(goods.tradeSymbol);
  if (units < 1) {
    return null;
  }
  // And we have the desired cargo.
  final response =
      await deliverContract(api, ship, contract, goods.tradeSymbol, units);
  final deliver = response.contract.goodNeeded(goods.tradeSymbol)!;
  shipInfo(
    ship,
    'Delivered $units ${goods.tradeSymbol} '
    'to ${goods.destinationSymbol}; '
    '${deliver.unitsFulfilled}/${deliver.unitsRequired}, '
    '${durationString(contract.timeUntilDeadline)} to deadline',
  );
  return response;
}

// I couldn't figure out how to use record types to do this.
class _Opportunity {
  _Opportunity(this.waypoint, this.purchasePrice);
  final Waypoint waypoint;
  final int purchasePrice;
}

Stream<_Opportunity> _nearbyMarketsWithProfitableTrade(
  Ship ship,
  PriceData priceData,
  WaypointCache waypointCache,
  MarketCache marketCache, {
  required String tradeSymbol,
  required int breakevenUnitPrice,
  int maxJumps = 5,
}) async* {
  await for (final waypoint in waypointsInJumpRadius(
    waypointCache: waypointCache,
    startSystem: ship.nav.systemSymbol,
    maxJumps: maxJumps,
  )) {
    if (!waypoint.hasMarketplace) {
      continue;
    }
    final market = await marketCache.marketForSymbol(waypoint.symbol);
    if (market == null) {
      shipErr(ship, 'Waypoint ${waypoint.symbol} hasMarket but no market??');
      continue;
    }
    if (!market.allowsTradeOf(tradeSymbol)) {
      continue;
    }
    final purchasePrice = estimatePurchasePrice(
      priceData,
      market,
      tradeSymbol,
    );
    if (purchasePrice == null) {
      // Most common reason for estimatePurchasePrice to return null is that
      // the market doesn't trade in that symbol, but we already checked that
      // above, so if we hit this it's a different reason.
      shipInfo(
        ship,
        'Cannot estimate price for $tradeSymbol at ${waypoint.symbol}',
      );
      continue;
    }
    // And our contract goal is selling < contract profit unit price.
    if (purchasePrice < breakevenUnitPrice) {
      yield _Opportunity(waypoint, purchasePrice);
    } else {
      shipDetail(
        ship,
        '${waypoint.symbol} has $tradeSymbol, but it is too expensive '
        '< $breakevenUnitPrice, got $purchasePrice',
      );
    }
  }
}

Future<DateTime?> _navigateToNearbyMarketIfNeeded(
  Api api,
  PriceData priceData,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  BehaviorManager behaviorManager, {
  required String tradeSymbol,
  required int breakevenUnitPrice,
}) async {
  // Find the nearest market within maxJumps that has the tradeSymbol
  // either at or below our profit unit price.
  final opportunity = await _nearbyMarketsWithProfitableTrade(
    ship,
    priceData,
    waypointCache,
    marketCache,
    tradeSymbol: tradeSymbol,
    breakevenUnitPrice: breakevenUnitPrice,
  ).firstOrNull;
  if (opportunity == null) {
    shipErr(
      ship,
      'No markets nearby with $tradeSymbol, disabling contract trader.',
    );
    // This probably isn't quite right?  We should instead search wider?
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }

  final priceDeviance = stringForPriceDeviance(
    priceData,
    tradeSymbol,
    opportunity.purchasePrice,
    MarketTransactionTypeEnum.PURCHASE,
  );
  final priceString = creditsString(opportunity.purchasePrice);
  final breakEvenString = creditsString(breakevenUnitPrice);
  shipInfo(
      ship,
      '${opportunity.waypoint.symbol} trades '
      '$tradeSymbol at $priceString $priceDeviance, below break '
      'even price $breakEvenString, routing.');
  final arrival = await beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    opportunity.waypoint.symbol,
  );
  return arrival;
}

// This is split out from the main function to allow early returns.
Future<bool> _purchaseContractGoodIfPossible(
  Api api,
  PriceData priceData,
  TransactionLog transactionLog,
  Ship ship,
  Waypoint currentWaypoint,
  MarketTradeGood maybeGood,
  ContractDeliverGood neededGood, {
  required int breakEvenUnitPrice,
  required int unitsToPurchase,
}) async {
  // And its selling at a reasonable price.
  if (maybeGood.purchasePrice >= breakEvenUnitPrice) {
    shipInfo(
      ship,
      '${neededGood.tradeSymbol} is too expensive near '
      '${currentWaypoint.symbol} '
      'needed < $breakEvenUnitPrice, got ${maybeGood.purchasePrice}',
    );
    return false;
  }

  if (ship.cargo.availableSpace <= 0) {
    shipInfo(
      ship,
      'No cargo space available to purchase ${neededGood.tradeSymbol}',
    );
    return false;
  }
  // Do we need to guard against insufficient credits here?
  // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
  // Buy a full stock of contract goal.
  // TODO(eseidel): this can fail.
  await purchaseCargoAndLog(
    api,
    priceData,
    transactionLog,
    ship,
    neededGood.tradeSymbol,
    unitsToPurchase,
  );
  return true;
}

/// Returns a list of all active (not fulfilled or expired) contracts.
Future<List<Contract>> activeContracts(Api api) async {
  final allContracts = await allMyContracts(api).toList();
  // Filter out the ones we've already done or have expired.
  return allContracts.where((c) => !c.fulfilled && !c.isExpired).toList();
}

/// One loop of the trading logic
Future<DateTime?> advanceContractTrader(
  Api api,
  DataStore db,
  PriceData priceData,
  Agent agent,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  TransactionLog transactionLog,
  BehaviorManager behaviorManager,
) async {
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    waypointCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  // Should this contract lookup move into the contract trader?
  final contracts = await activeContracts(api);
  if (contracts.length > 1) {
    shipWarn(ship, '${contracts.length} contracts! Only servicing the first.');
  }
  final contract = contracts.firstOrNull;
  if (contract == null) {
    await negotiateContractAndLog(api, ship);
    return null;
  }
  if (!contract.accepted) {
    await acceptContractAndLog(api, contract);
  }
  final neededGood = contract.terms.deliver.first;
  final totalPayment =
      contract.terms.payment.onAccepted + contract.terms.payment.onFulfilled;
  // TODO(eseidel): "break even" should include a minimum margin.
  final breakEvenUnitPrice = totalPayment ~/ neededGood.unitsRequired;

  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  final currentMarket = await marketCache
      .marketForSymbol(currentWaypoint.symbol, forceRefresh: true);

  // If we're currently at a market, record the prices and refuel.
  if (currentMarket != null) {
    await dockIfNeeded(api, ship);
    await refuelIfNeededAndLog(
      api,
      priceData,
      transactionLog,
      agent,
      currentMarket,
      ship,
    );
    await recordMarketData(priceData, currentMarket);
  }

  // If we're at our contract destination.
  if (currentWaypoint.symbol == neededGood.destinationSymbol) {
    final maybeResponse =
        await _deliverContractGoodsIfPossible(api, ship, contract, neededGood);

    // Delivering the goods counts as completing the behavior, we'll
    // decide next loop if we need to do more.
    await behaviorManager.completeBehavior(ship.symbol);

    if (maybeResponse != null) {
      // Update our cargo counts after fulfilling the contract.
      ship.cargo = maybeResponse.cargo;
      // If we've delivered enough, complete the contract.
      if (maybeResponse.contract
              .goodNeeded(neededGood.tradeSymbol)!
              .amountNeeded <=
          0) {
        await api.contracts.fulfillContract(contract.id);
        shipInfo(ship, 'Contract complete!');
        return null;
      }
    }
  }

  // We should only use the contract trader when we have enough credits to
  // complete the entire contract.  Otherwise we're just sinking credits
  // into a contract we can't complete yet when we could be using that
  // money for other trading.
  // Make sure we only to our credit check *after* we deliver our goods.
  const creditsBuffer = 20000;
  final remainingUnits = neededGood.unitsRequired - neededGood.unitsFulfilled;
  final minimumCreditsToTrade =
      max(100000, breakEvenUnitPrice * remainingUnits + creditsBuffer);
  if (agent.credits < minimumCreditsToTrade) {
    shipWarn(
      ship,
      'Not enough credits complete contract, disabling contract trader.',
    );
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }

  // We might still be at our contract destination.
  // Which might be a bad deal to buy from!
  // If we're at a market, buy our goods.
  if (currentWaypoint.hasMarketplace) {
    // Sell everything we have except the contract goal.
    if (ship.cargo.isNotEmpty) {
      await sellAllCargoAndLog(
        api,
        priceData,
        transactionLog,
        ship,
        where: (s) => s != neededGood.tradeSymbol,
      );
    }

    await recordMarketData(priceData, currentMarket!);
    final maybeGood = currentMarket.tradeGoods
        .firstWhereOrNull((g) => g.symbol == neededGood.tradeSymbol);

    // If this market has our desired goods:
    if (maybeGood == null) {
      shipInfo(
        ship,
        'Market at ${currentWaypoint.symbol} does not have '
        '${neededGood.tradeSymbol}',
      );
    } else {
      // TODO(eseidel): This has the potential of racing with multiple ships.
      final unitsInCargo = ship.cargo.countUnits(neededGood.tradeSymbol);
      final unitsNeeded = max(
        0,
        neededGood.unitsRequired - neededGood.unitsFulfilled - unitsInCargo,
      );
      if (unitsNeeded <= 0) {
        shipInfo(
          ship,
          'Already have $unitsInCargo ${neededGood.tradeSymbol} in '
          'cargo which is enough to fulfill contract '
          '(${neededGood.unitsFulfilled}/${neededGood.unitsRequired}) '
          'at ${currentWaypoint.symbol}',
        );
      } else {
        // Constrain by both tradeVolume and our cargo space.
        final unitsToPurchase = min(
          min(
            unitsNeeded,
            maybeGood.tradeVolume,
          ),
          ship.cargo.availableSpace,
        );
        final creditsNeeded = unitsToPurchase * maybeGood.purchasePrice;
        if (agent.credits < creditsNeeded) {
          // If we have some to deliver, deliver it.
          if (unitsInCargo > 0) {
            shipInfo(
              ship,
              'Not enough credits to purchase $unitsToPurchase '
              '${neededGood.tradeSymbol} at ${currentWaypoint.symbol}, '
              'but we have $unitsInCargo in cargo, delivering.',
            );
          } else {
            // This should print the pricing of the good we're trying to buy.
            shipErr(
              ship,
              'Not enough credits to purchase $unitsToPurchase '
              '${neededGood.tradeSymbol} at ${currentWaypoint.symbol}, '
              'disabling contract trader.',
            );
            await behaviorManager.disableBehavior(
              ship,
              Behavior.contractTrader,
            );
            return null;
          }
        } else {
          // If we have the money, do the purchase.
          final succeeded = await _purchaseContractGoodIfPossible(
            api,
            priceData,
            transactionLog,
            ship,
            currentWaypoint,
            maybeGood,
            neededGood,
            breakEvenUnitPrice: breakEvenUnitPrice,
            unitsToPurchase: unitsToPurchase,
          );

          if (succeeded && ship.cargo.availableSpace > 0) {
            shipInfo(
              ship,
              'Purchased $unitsToPurchase of $unitsNeeded needed, still have '
              '${ship.cargo.availableSpace} units of cargo space looping.',
            );
            return null;
          }
        }
      }
    }
  }
  // Do we already have our goods?
  // If so navigate to contract destination.
  if (ship.countUnits(neededGood.tradeSymbol) > 0) {
    return beingRouteAndLog(
      api,
      ship,
      waypointCache,
      behaviorManager,
      neededGood.destinationSymbol,
    );
  } else {
    // Do we need to check for sufficient credits here?
    return _navigateToNearbyMarketIfNeeded(
      api,
      priceData,
      ship,
      waypointCache,
      marketCache,
      behaviorManager,
      tradeSymbol: neededGood.tradeSymbol,
      breakevenUnitPrice: breakEvenUnitPrice,
    );
  }
}
