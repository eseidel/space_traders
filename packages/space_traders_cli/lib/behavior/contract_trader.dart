import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/actions.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/navigation.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:space_traders_cli/waypoint_cache.dart';

List<Market> _marketsWithExport(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exports.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

List<Market> _marketsWithExchange(
  String tradeSymbol,
  List<Market> markets,
) {
  return markets
      .where((m) => m.exchange.any((e) => e.symbol.value == tradeSymbol))
      .toList();
}

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

Future<DateTime?> _navigateToNearbyMarketIfNeeded(
  Api api,
  Ship ship,
  WaypointCache waypointCache,
  MarketCache marketCache,
  BehaviorManager behaviorManager,
  String tradeSymbol,
) async {
  // This needs to find nearby market with the desired tradeSymbol
  // ideally under median price.

  final allMarkets =
      await marketCache.marketsInSystem(ship.nav.systemSymbol).toList();

  // This should also consider the current market.
  var markets = _marketsWithExport(tradeSymbol, allMarkets);
  if (markets.isEmpty) {
    markets = _marketsWithExchange(tradeSymbol, allMarkets);
  }
  final marketSymbol = markets.firstOrNull?.symbol;
  if (marketSymbol == null) {
    shipErr(
      ship,
      'No markets nearby with $tradeSymbol, disabling contract trader.',
    );
    // This probably isn't quite right?  We should instead search wider?
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }
  final destination = await waypointCache.waypoint(marketSymbol);
  final arrival = await navigateToLocalWaypointAndLog(api, ship, destination);
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
  ContractDeliverGood? maybeGoods,
) async {
  if (maybeContract == null) {
    await negotiateContractAndLog(api, ship);
    return null;
  }
  final contract = maybeContract;
  final goods = maybeGoods!;
  if (agent.credits < 10000) {
    shipErr(ship, 'Not enough credits to trade, disabling contract trader.');
    await behaviorManager.disableBehavior(ship, Behavior.contractTrader);
    return null;
  }
  final navResult = await continueNavigationIfNeeded(
    api,
    ship,
    waypointCache,
    behaviorManager,
  );
  if (navResult.shouldReturn()) {
    return navResult.waitTime;
  }
  await dockIfNeeded(api, ship);
  await refuelIfNeededAndLog(api, priceData, agent, ship);
  final currentWaypoint = await waypointCache.waypoint(ship.nav.waypointSymbol);
  // If we're at our contract destination.
  if (currentWaypoint.symbol == goods.destinationSymbol) {
    final maybeResponse =
        await _deliverContractGoodsIfPossible(api, ship, contract, goods);

    // Delivering the goods counts as completing the behavior, we'll
    // decide next loop if we need to do more.
    await behaviorManager.completeBehavior(ship.symbol);

    if (maybeResponse != null) {
      // Update our cargo counts after fullfilling the contract.
      ship.cargo = maybeResponse.cargo;
      // If we've delivered enough, complete the contract.
      if (maybeResponse.contract.goodNeeded(goods.tradeSymbol)!.amountNeeded <=
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
      ship,
      waypointCache,
      marketCache,
      behaviorManager,
      goods.tradeSymbol,
    );
  }

  // Otherwise if we're not at our contract destination.
  // And it has a market.
  if (currentWaypoint.hasMarketplace) {
    final market = await marketCache.marketForSymbol(currentWaypoint.symbol);
    final maybeGood = market!.tradeGoods
        .firstWhereOrNull((g) => g.symbol == goods.tradeSymbol);
    final totalPayment =
        contract.terms.payment.onAccepted + contract.terms.payment.onFulfilled;
    final minimumProfitUnitPrice = totalPayment / goods.unitsRequired;
    // And our contract goal is selling < contract profit unit price.
    if (maybeGood != null && maybeGood.purchasePrice < minimumProfitUnitPrice) {
      // Sell everything we have except the contract goal.
      final cargo = await sellCargoAndLog(
        api,
        priceData,
        ship,
        where: (s) => s != goods.tradeSymbol,
      );
      if (cargo.availableSpace > 0) {
        // shipInfo(ship, 'Buying ${goods.tradeSymbol} to fill contract');
        // Buy a full stock of contract goal.
        await purchaseCargoAndLog(
          api,
          priceData,
          ship,
          goods.tradeSymbol,
          cargo.availableSpace,
        );
      }
    } else {
      // TODO(eseidel): This can't work.  We need to be able to do something
      // when things are too expensive.
      if (maybeGood != null) {
        shipInfo(
          ship,
          '${goods.tradeSymbol} is too expensive near ${currentWaypoint.symbol} '
          'needed < $minimumProfitUnitPrice, got ${maybeGood.purchasePrice}',
        );
      } else {
        shipInfo(
          ship,
          'No ${goods.tradeSymbol} available near ${currentWaypoint.symbol}',
        );
      }
      return _navigateToNearbyMarketIfNeeded(
        api,
        ship,
        waypointCache,
        marketCache,
        behaviorManager,
        goods.tradeSymbol,
      );
    }
  }
  // Regardless, navigate to contract destination.
  return beingRouteAndLog(
    api,
    ship,
    waypointCache,
    behaviorManager,
    goods.destinationSymbol,
  );
}
