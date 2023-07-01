import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/direct.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';

export 'package:cli/net/direct.dart';

// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.

/// Navigate [ship] to [waypointSymbol] will retry in drift mode if
/// there is insufficient fuel.
Future<NavigateShip200ResponseData> navigateToLocalWaypoint(
  Api api,
  Ship ship,
  String waypointSymbol,
) async {
  await undockIfNeeded(api, ship);
  try {
    return await navigateShip(api, ship, waypointSymbol);
  } on ApiException catch (e) {
    if (!isInfuficientFuelException(e)) {
      rethrow;
    }
    shipWarn(ship, 'Insufficient fuel, drifting to $waypointSymbol');
    await setShipFlightMode(api, ship, ShipNavFlightMode.DRIFT);
    return navigateShip(api, ship, waypointSymbol);
  }
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellAllCargo(
  Api api,
  AgentCache agentCache,
  Market market,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async* {
  // This should not sell anything we have a contract for.
  // We should travel first to the marketplace that has the best price for
  // the ore we have a contract for.
  for (final item in ship.cargo.inventory) {
    if (where != null && !where(item.symbol)) {
      continue;
    }
    final good = market.marketTradeGood(item.symbol);
    if (good == null) {
      shipInfo(
        ship,
        "Market at ${ship.nav.waypointSymbol} doesn't buy ${item.symbol}",
      );
      continue;
    }
    assert(
      good.tradeVolume > 0,
      'Market has 0 trade volume for ${good.symbol}',
    );
    var leftToSell = item.units;
    while (leftToSell > 0) {
      final toSell = min(leftToSell, good.tradeVolume);
      leftToSell -= toSell;
      final response = await sellCargo(
        api,
        agentCache,
        ship,
        TradeSymbol.fromJson(item.symbol)!,
        toSell,
      );
      yield response;
    }
  }
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// Logs each transaction or "No cargo to sell" if there is no cargo.
Future<List<Transaction>> sellAllCargoAndLog(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Market market,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async {
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return [];
  }

  final transactions = <Transaction>[];
  await for (final response
      in sellAllCargo(api, agentCache, market, ship, where: where)) {
    final marketTransaction = response.transaction;
    final agent = response.agent;
    logTransaction(ship, marketPrices, agent, marketTransaction);
    final transaction =
        Transaction.fromMarketTransaction(marketTransaction, agent.credits);
    transactionLog.log(transaction);
    transactions.add(transaction);
  }
  return transactions;
}

/// Buy [amountToBuy] units of [tradeSymbol] and log the transaction.
Future<Transaction?> purchaseCargoAndLog(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Ship ship,
  TradeSymbol tradeSymbol,
  int amountToBuy,
) async {
  // TODO(eseidel): Move trade volume and cargo space checks inside here.
  try {
    final data =
        await purchaseCargo(api, agentCache, ship, tradeSymbol, amountToBuy);
    // Do we need to handle transaction limits?  Callers should check before.
    // ApiException 400: {"error":{"message":"Market transaction failed.
    // Trade good REACTOR_FUSION_I has a limit of 10 units per transaction.",
    // "code":4604,"data":{"waypointSymbol":"X1-UC8-13100A","tradeSymbol":
    // "REACTOR_FUSION_I","units":60,"tradeVolume":10}}}
    final agent = data.agent;
    final marketTransaction = data.transaction;
    logTransaction(ship, marketPrices, agent, marketTransaction);
    final transaction = Transaction.fromMarketTransaction(
      marketTransaction,
      agent.credits,
    );
    transactionLog.log(transaction);
    return transaction;
  } on ApiException catch (e) {
    if (!isInsufficientCreditsException(e)) {
      rethrow;
    }
    shipWarn(
        ship,
        'Purchase of $amountToBuy $tradeSymbol failed. '
        'Insufficient credits.');
    return null;
  }
}

/// Log a shipyard transaction to the console.
void logShipyardTransaction(
  Ship ship,
  MarketPrices marketPrices,
  Agent agent,
  ShipyardTransaction t,
) {
  shipInfo(
      ship,
      'Purchased ${t.shipSymbol} for '
      '${creditsString(t.price)} -> ');
  final afterCredits = creditsString(agent.credits);
  logger.info('$afterCredits credits remaining.');
}

/// Purchase a ship and log the transaction.
Future<PurchaseShip201ResponseData> purchaseShipAndLog(
  Api api,
  MarketPrices marketPrices,
  ShipCache shipCache,
  AgentCache agentCache,
  Ship ship,
  String shipyardSymbol,
  ShipType shipType,
) async {
  final result =
      await purchaseShip(api, shipCache, agentCache, shipyardSymbol, shipType);
  logShipyardTransaction(ship, marketPrices, result.agent, result.transaction);
  return result;
}

bool _shouldRefuelAfterCheckingPrice(
  MarketPrices marketPrices,
  Ship ship,
  int fuelPrice,
) {
  final fuelSymbol = TradeSymbol.FUEL.value;
  final median = marketPrices.medianPurchasePrice(fuelSymbol);
  final markup = median != null ? fuelPrice / median : null;
  if (markup != null && markup > 2) {
    final deviation = stringForPriceDeviance(
      marketPrices,
      fuelSymbol,
      fuelPrice,
      MarketTransactionTypeEnum.PURCHASE,
    );
    final fuelString = creditsString(fuelPrice);

    final fuelPercent = ship.fuel.current / ship.fuel.capacity;
    if (fuelPercent < 0.5) {
      shipWarn(
          ship,
          'Fuel low: ${ship.fuel.current} / '
          '${ship.fuel.capacity}}');
    }
    final markupString = markup.toStringAsFixed(1);
    // The really bonkers prices are 100x median.
    if (markup > 10 || fuelPercent > 0.5) {
      shipWarn(
        ship,
        'Fuel is at $markupString times the median price '
        '$fuelString ($deviation), not refueling.',
      );
      return false; // Do not refuel.
    }
    shipWarn(
        ship,
        'Fuel is at $markupString times the median price '
        '$fuelString ($deviation), but also critically low, refueling anyway');
  }
  return true; // Refuel.
}

/// Refuel the ship if needed and log the transaction
Future<RefuelShip200ResponseData?> refuelIfNeededAndLog(
  Api api,
  MarketPrices marketPrices,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Market market,
  Ship ship,
) async {
  if (!ship.shouldRefuel) {
    return null;
  }
  // Ensure the fuel here is not wildly overpriced (as is sometimes the case).
  final fuelGood = market.marketTradeGood(TradeSymbol.FUEL.value);
  if (fuelGood == null) {
    shipWarn(ship, 'Market does not sell fuel, not refueling.');
    return null;
  }
  if (!_shouldRefuelAfterCheckingPrice(
    marketPrices,
    ship,
    fuelGood.purchasePrice,
  )) {
    return null;
  }
  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  try {
    final data = await refuelShip(api, agentCache, ship);
    final transaction = data.transaction;
    final agent = agentCache.agent;
    logTransaction(
      ship,
      marketPrices,
      agent,
      transaction,
      transactionEmoji: '⛽',
    );
    transactionLog.log(
      Transaction.fromMarketTransaction(transaction, agent.credits),
    );
    // Reset flight mode on refueling.
    if (ship.nav.flightMode != ShipNavFlightMode.CRUISE) {
      shipInfo(ship, 'Resetting flight mode to cruise');
      await setShipFlightMode(api, ship, ShipNavFlightMode.CRUISE);
    }
    return data;
  } on ApiException catch (e) {
    // This should no longer be needed now that we check if the market sells
    // fuel before trying to purchase.
    if (!isMarketDoesNotSellFuelException(e)) {
      rethrow;
    }
    shipInfo(ship, 'Market does not sell fuel, not refueling.');
  }
  return null;
}

/// Dock the ship if needed and log the transaction
Future<void> dockIfNeeded(Api api, Ship ship) async {
  if (ship.isOrbiting) {
    shipDetail(ship, '🛬 at ${ship.nav.waypointSymbol}');
    final response = await api.fleet.dockShip(ship.symbol);
    ship.nav = response!.data.nav;
  }
}

/// Undock the ship if needed and log the transaction
Future<void> undockIfNeeded(Api api, Ship ship) async {
  if (ship.isDocked) {
    // Extra space after emoji is needed for windows powershell.
    shipDetail(ship, '🛰️  at ${ship.nav.waypointSymbol}');
    final response = await api.fleet.orbitShip(ship.symbol);
    ship.nav = response!.data.nav;
  }
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> navigateToLocalWaypointAndLog(
  Api api,
  Ship ship,
  SystemWaypoint waypoint,
) async {
  // Should this dock and refuel and reset the flight mode if needed?
  // if (ship.shouldRefuel) {
  //   await refuelIfNeededAndLog(api, marketPrices, agent, ship);
  // }

  final result = await navigateToLocalWaypoint(api, ship, waypoint.symbol);
  final flightTime = result.nav.route.arrival.difference(DateTime.now());
  if (ship.fuelPercentage < 0.5) {
    shipWarn(
      ship,
      'Fuel low: ${ship.fuel.current} / ${ship.fuel.capacity}}',
    );
  }
  // Could log used Fuel. result.fuel.fuelConsumed
  shipInfo(
    ship,
    '🛫 to ${waypoint.symbol} ${waypoint.type} '
    '(${durationString(flightTime)}) '
    'spent ${result.fuel.consumed?.amount} fuel',
  );
  return result.nav.route.arrival;
}

/// Chart the waypoint [ship] is currently at and log.
Future<void> chartWaypointAndLog(Api api, Ship ship) async {
  try {
    final response = await api.fleet.createChart(ship.symbol);
    final waypoint = response!.data.waypoint;
    // Powershell needs the space after the emoji.
    shipInfo(ship, '🗺️  ${waypointDescription(waypoint)}');
  } on ApiException catch (e) {
    if (!isWaypointAlreadyChartedException(e)) {
      rethrow;
    }
    shipWarn(ship, '${ship.nav.waypointSymbol} was already charted');
  }
}

/// Use the jump gate to travel to [systemSymbol] and log.
Future<JumpShip200ResponseData> useJumpGateAndLog(
  Api api,
  Ship ship,
  String systemSymbol,
) async {
  final jumpShipRequest = JumpShipRequest(systemSymbol: systemSymbol);
  final response =
      await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpShipRequest);
  ship.nav = response!.data.nav;
  shipInfo(ship, 'Used Jump Gate to $systemSymbol');
  return response.data;
}

/// Negotiate a contract for [ship] and log.
Future<Contract> negotiateContractAndLog(Api api, Ship ship) async {
  await dockIfNeeded(api, ship);
  final response = await api.fleet.negotiateContract(ship.symbol);
  final contractData = response!.data;
  final contract = contractData.contract;
  shipInfo(ship, 'Negotiated contract: ${contractDescription(contract)}');
  return contract;
}

/// Accept [contract] and log.
Future<AcceptContract200ResponseData> acceptContractAndLog(
  Api api,
  ContractCache contractCache,
  AgentCache agentCache,
  Contract contract,
) async {
  final response = await api.contracts.acceptContract(contract.id);
  final data = response!.data;
  agentCache.updateAgent(data.agent);
  await contractCache.updateContract(data.contract);
  logger
    ..info('Accepted: ${contractDescription(contract)}.')
    ..info(
      'received ${creditsString(contract.terms.payment.onAccepted)}',
    );
  return data;
}

/// Install [mountSymbol] on [ship] and log.
Future<InstallMount201ResponseData> installMountAndLog(
  Api api,
  Ship ship,
  String mountSymbol,
) async {
  final request = InstallMountRequest(symbol: mountSymbol);
  final response =
      await api.fleet.installMount(ship.symbol, installMountRequest: request);
  // Not changing agent.
  ship
    ..mounts = response!.data.mounts
    ..cargo = response.data.cargo;
  return response.data;
}

/// Remove [mountSymbol] from [ship] and log.
Future<RemoveMount201ResponseData> removeMountAndLog(
  Api api,
  Ship ship,
  String mountSymbol,
) async {
  final request = RemoveMountRequest(symbol: mountSymbol);
  final response =
      await api.fleet.removeMount(ship.symbol, removeMountRequest: request);
  // Not changing agent.
  ship
    ..mounts = response!.data.mounts
    ..cargo = response.data.cargo;
  return response.data;
}
