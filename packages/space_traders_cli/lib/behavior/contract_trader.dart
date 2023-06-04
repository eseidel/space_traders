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
    if (waypoint.symbol == ship.nav.waypointSymbol) {
      continue;
    }
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
      continue;
    }
    final maybeGood =
        market.tradeGoods.firstWhereOrNull((g) => g.symbol == tradeSymbol);
    if (maybeGood == null) {
      continue;
    }
    // And our contract goal is selling < contract profit unit price.
    if (maybeGood.purchasePrice < breakevenUnitPrice) {
      yield waypoint;
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
  // either at or below our profit unit price, or as an export.
  final nearbyMarket = await _nearbyMarketsWithProfitableTrade(
    ship,
    priceData,
    waypointCache,
    marketCache,
    tradeSymbol: tradeSymbol,
    breakevenUnitPrice: breakevenUnitPrice,
  ).firstOrNull;

  // TODO(eseidel): Failing that, find a market with tradeSymbol as an exchange.
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
  if (agent.credits < 10000) {
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

    // Sell anything we have.
    await sellCargoAndLog(api, priceData, ship);
    // nav to place nearby exporting our contract goal.
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

  // Otherwise if we're not at our contract destination.
  // And it has a market.
  if (currentWaypoint.hasMarketplace) {
    final market = await marketCache.marketForSymbol(currentWaypoint.symbol);
    final maybeGood = market!.tradeGoods
        .firstWhereOrNull((g) => g.symbol == neededGood.tradeSymbol);
    // And our contract goal is selling < contract profit unit price.
    if (maybeGood != null && maybeGood.purchasePrice < breakEvenUnitPrice) {
      // Sell everything we have except the contract goal.
      final cargo = await sellCargoAndLog(
        api,
        priceData,
        ship,
        where: (s) => s != neededGood.tradeSymbol,
      );
      if (cargo.availableSpace > 0) {
        // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
        // Buy a full stock of contract goal.
        await purchaseCargoAndLog(
          api,
          priceData,
          ship,
          neededGood.tradeSymbol,
          cargo.availableSpace,
        );
      }
    } else {
      // TODO(eseidel): This can't work.  We need to be able to do something
      // when things are too expensive.
      if (maybeGood != null) {
        shipInfo(
          ship,
          '${neededGood.tradeSymbol} is too expensive near '
          '${currentWaypoint.symbol} '
          'needed < $breakEvenUnitPrice, got ${maybeGood.purchasePrice}',
        );
      } else {
        shipInfo(
          ship,
          'No ${neededGood.tradeSymbol} available near '
          '${currentWaypoint.symbol}',
        );
      }
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
  // Regardless, navigate to contract destination.
  return beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    neededGood.destinationSymbol,
  );
}
