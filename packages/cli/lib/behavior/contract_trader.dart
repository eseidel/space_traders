import 'dart:math';

import 'package:async/async.dart';
import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/navigation.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/printing.dart';
import 'package:cli/trading.dart';
import 'package:collection/collection.dart';

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
  MarketPrices marketPrices,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache, {
  required String tradeSymbol,
  required int maximumWorthwhileUnitPurchasePrice,
  int maxJumps = 5,
}) async* {
  await for (final waypoint in waypointCache.waypointsInJumpRadius(
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
      marketPrices,
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
    if (purchasePrice < maximumWorthwhileUnitPurchasePrice) {
      yield _Opportunity(waypoint, purchasePrice);
    } else {
      shipDetail(
        ship,
        '${waypoint.symbol} has $tradeSymbol, but it is too expensive '
        '< $maximumWorthwhileUnitPurchasePrice, got $purchasePrice',
      );
    }
  }
}

Future<DateTime?> _navigateToNearbyMarketIfNeeded(
  Api api,
  MarketPrices marketPrices,
  Ship ship,
  SystemsCache systemsCache,
  WaypointCache waypointCache,
  MarketCache marketCache,
  CentralCommand centralCommand, {
  required String tradeSymbol,
  required int maximumWorthwhileUnitPurchasePrice,
}) async {
  // Find the nearest market within maxJumps that has the tradeSymbol
  // either at or below our profit unit price.
  final opportunity = await _nearbyMarketsWithProfitableTrade(
    ship,
    marketPrices,
    systemsCache,
    waypointCache,
    marketCache,
    tradeSymbol: tradeSymbol,
    maximumWorthwhileUnitPurchasePrice: maximumWorthwhileUnitPurchasePrice,
    maxJumps: 10,
  ).firstOrNull;
  if (opportunity == null) {
    // This probably isn't quite right?  We should instead search wider?
    await centralCommand.disableBehavior(
      ship,
      Behavior.contractTrader,
      'No markets nearby with $tradeSymbol.',
      const Duration(hours: 1),
    );
    return null;
  }

  final priceDeviance = stringForPriceDeviance(
    marketPrices,
    tradeSymbol,
    opportunity.purchasePrice,
    MarketTransactionTypeEnum.PURCHASE,
  );
  final priceString = creditsString(opportunity.purchasePrice);
  final breakEvenString = creditsString(maximumWorthwhileUnitPurchasePrice);
  shipInfo(
      ship,
      '${opportunity.waypoint.symbol} trades '
      '$tradeSymbol at $priceString $priceDeviance, below break '
      'even price $breakEvenString, routing.');
  final arrival = await beingRouteAndLog(
    api,
    ship,
    systemsCache,
    centralCommand,
    opportunity.waypoint.symbol,
  );
  return arrival;
}

// This is split out from the main function to allow early returns.
Future<bool> _purchaseContractGoodIfPossible(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Ship ship,
  Waypoint currentWaypoint,
  MarketTradeGood maybeGood,
  ContractDeliverGood neededGood, {
  required int maximumWorthwhileUnitPurchasePrice,
  required int unitsToPurchase,
}) async {
  // And its selling at a reasonable price.
  if (maybeGood.purchasePrice >= maximumWorthwhileUnitPurchasePrice) {
    shipInfo(
      ship,
      '${neededGood.tradeSymbol} is too expensive near '
      '${currentWaypoint.symbol} '
      'needed < $maximumWorthwhileUnitPurchasePrice, '
      'got ${maybeGood.purchasePrice}',
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
    marketPrices,
    transactionLog,
    agentCache,
    ship,
    TradeSymbol.fromJson(neededGood.tradeSymbol)!,
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
  CentralCommand centralCommand,
  Caches caches,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  assert(!ship.isInTransit, 'Ship ${ship.symbol} is in transit');
  // Should this contract lookup move into the contract trader?
  final contracts = await activeContracts(api);
  if (contracts.length > 1) {
    shipWarn(ship, '${contracts.length} contracts! Only servicing the first.');
  }
  final contract = contracts.firstOrNull;
  if (contract == null) {
    await negotiateContractAndLog(api, ship);
    // TODO(eseidel): Print expected time and profits of the new contract.
    return null;
  }
  if (!contract.accepted) {
    await acceptContractAndLog(api, contract);
  }
  final neededGood = contract.terms.deliver.first;
  final totalPayment =
      contract.terms.payment.onAccepted + contract.terms.payment.onFulfilled;
  // TODO(eseidel): "break even" should include a minimum margin.
  final maximumWorthwhileUnitPurchasePrice =
      totalPayment ~/ neededGood.unitsRequired;

  final currentWaypoint =
      await caches.waypoints.waypoint(ship.nav.waypointSymbol);
  final currentMarket = await caches.markets
      .marketForSymbol(currentWaypoint.symbol, forceRefresh: true);

  // If we're currently at a market, record the prices and refuel.
  if (currentMarket != null) {
    await dockIfNeeded(api, ship);
    await refuelIfNeededAndLog(
      api,
      caches.marketPrices,
      caches.transactions,
      caches.agent,
      currentMarket,
      ship,
    );
    await recordMarketData(caches.marketPrices, currentMarket);
  }

  // If we're at our contract destination.
  if (currentWaypoint.symbol == neededGood.destinationSymbol) {
    final maybeResponse =
        await _deliverContractGoodsIfPossible(api, ship, contract, neededGood);

    // Delivering the goods counts as completing the behavior, we'll
    // decide next loop if we need to do more.
    await centralCommand.completeBehavior(ship.symbol);

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
  final minimumCreditsToTrade = max(
    100000,
    maximumWorthwhileUnitPurchasePrice * remainingUnits + creditsBuffer,
  );
  if (caches.agent.agent.credits < minimumCreditsToTrade) {
    await centralCommand.disableBehavior(
      ship,
      Behavior.contractTrader,
      'Not enough credits (${creditsString(caches.agent.agent.credits)}) to '
      'complete contract (${creditsString(minimumCreditsToTrade)}).',
      const Duration(hours: 1),
    );
    return null;
  }

  // We might still be at our contract destination.
  // Which might be a bad deal to buy from!
  // If we're at a market, buy our goods.
  if (currentMarket != null) {
    // Sell everything we have except the contract goal.
    if (ship.cargo.isNotEmpty) {
      await sellAllCargoAndLog(
        api,
        caches.marketPrices,
        caches.transactions,
        caches.agent,
        currentMarket,
        ship,
        where: (s) => s != neededGood.tradeSymbol,
      );
    }

    await recordMarketData(caches.marketPrices, currentMarket);
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
        if (caches.agent.agent.credits < creditsNeeded) {
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
            await centralCommand.disableBehavior(
              ship,
              Behavior.contractTrader,
              'Not enough credits to purchase $unitsToPurchase '
              '${neededGood.tradeSymbol} at ${currentWaypoint.symbol}',
              const Duration(hours: 1),
            );
            return null;
          }
        } else {
          // If we have the money, do the purchase.
          final succeeded = await _purchaseContractGoodIfPossible(
            api,
            caches.marketPrices,
            caches.transactions,
            caches.agent,
            ship,
            currentWaypoint,
            maybeGood,
            neededGood,
            maximumWorthwhileUnitPurchasePrice:
                maximumWorthwhileUnitPurchasePrice,
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
      caches.systems,
      centralCommand,
      neededGood.destinationSymbol,
    );
  } else {
    // Do we need to check for sufficient credits here?
    return _navigateToNearbyMarketIfNeeded(
      api,
      caches.marketPrices,
      ship,
      caches.systems,
      caches.waypoints,
      caches.markets,
      centralCommand,
      tradeSymbol: neededGood.tradeSymbol,
      maximumWorthwhileUnitPurchasePrice: maximumWorthwhileUnitPurchasePrice,
    );
  }
}