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

Stream<Waypoint> _nearbyMarketsWithProfitableTrade(
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
    final purchasePrice = estimatePurchasePrice(
      priceData,
      market,
      tradeSymbol,
    );
    if (purchasePrice == null) {
      shipInfo(
        ship,
        'Cannot estimate price for $tradeSymbol at ${waypoint.symbol}',
      );
      continue;
    }
    // And our contract goal is selling < contract profit unit price.
    if (purchasePrice < breakevenUnitPrice) {
      yield waypoint;
    } else {
      shipInfo(
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
  final nearbyMarket = await _nearbyMarketsWithProfitableTrade(
    ship,
    priceData,
    waypointCache,
    marketCache,
    tradeSymbol: tradeSymbol,
    breakevenUnitPrice: breakevenUnitPrice,
  ).firstOrNull;
  if (nearbyMarket == null) {
    shipErr(
      ship,
      'No markets nearby with $tradeSymbol, disabling contract trader.',
    );
    // This probably isn't quite right?  We should instead search wider?
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }

  final arrival = await beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    nearbyMarket.symbol,
  );
  return arrival;
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
  BehaviorManager behaviorManager,
  Contract? maybeContract,
  ContractDeliverGood? maybeGood,
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
  if (maybeContract == null) {
    await negotiateContractAndLog(api, ship);
    return null;
  }
  final contract = maybeContract;
  final neededGood = maybeGood!;
  // min credits could be relative to the good traded / size of cargo hold?
  const minimumCreditsToTrade = 100000;
  if (agent.credits < minimumCreditsToTrade) {
    shipErr(ship, 'Not enough credits to trade, disabling contract trader.');
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }
  final totalPayment =
      contract.terms.payment.onAccepted + contract.terms.payment.onFulfilled;
  final breakEvenUnitPrice = totalPayment ~/ neededGood.unitsRequired;

  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
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

  // We might still be at our contract destination.
  // If we're at a market, buy our goods.
  if (currentWaypoint.hasMarketplace) {
    // Sell everything we have except the contract goal.
    final cargo = await sellCargoAndLog(
      api,
      priceData,
      ship,
      where: (s) => s != neededGood.tradeSymbol,
    );

    final market = await marketCache.marketForSymbol(currentWaypoint.symbol);
    final maybeGood = market!.tradeGoods
        .firstWhereOrNull((g) => g.symbol == neededGood.tradeSymbol);
    // If this market has our desired goods:
    if (maybeGood != null) {
      // TODO(eseidel): This has the potential of racing with multiple ships.
      final unitsInCargo = cargo.countUnits(neededGood.tradeSymbol);
      final unitsNeeded = max(
        0,
        neededGood.unitsRequired - neededGood.unitsFulfilled - unitsInCargo,
      );
      // And its selling at a reasonable price.
      if (unitsNeeded > 0) {
        if (maybeGood.purchasePrice < breakEvenUnitPrice) {
          if (cargo.availableSpace > 0) {
            final unitsToPurchase = min(
              unitsNeeded,
              maybeGood.tradeVolume,
            );
            // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
            // Buy a full stock of contract goal.
            await purchaseCargoAndLog(
              api,
              priceData,
              ship,
              neededGood.tradeSymbol,
              unitsToPurchase,
            );
            if (unitsToPurchase < unitsNeeded) {
              shipInfo(
                ship,
                'Purchased $unitsToPurchase of $unitsNeeded needed, looping.',
              );
              return null;
            }
          }
        } else {
          shipInfo(
            ship,
            '${neededGood.tradeSymbol} is too expensive near '
            '${currentWaypoint.symbol} '
            'needed < $breakEvenUnitPrice, got ${maybeGood.purchasePrice}',
          );
        }
      } else {
        shipInfo(
          ship,
          'Already have $unitsInCargo ${neededGood.tradeSymbol} in '
          'cargo which is enough to fulfill contract '
          '(${neededGood.unitsFulfilled}/${neededGood.unitsRequired}) '
          'at ${currentWaypoint.symbol}',
        );
      }
    } else {
      shipInfo(
        ship,
        'Market at ${currentWaypoint.symbol} does not have '
        '${neededGood.tradeSymbol}',
      );
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
