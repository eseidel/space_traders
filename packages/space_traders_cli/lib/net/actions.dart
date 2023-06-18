import 'dart:math';

import 'package:collection/collection.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/exceptions.dart';
import 'package:space_traders_cli/printing.dart';

// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.
// They don't currently update agent (credits), but probably should too.

/// Purchase a ship of type [shipType] at [shipyardSymbol]
Future<PurchaseShip201ResponseData> purchaseShip(
  Api api,
  ShipCache shipCache,
  AgentCache agentCache,
  String shipyardSymbol,
  ShipType shipType,
) async {
  final purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardSymbol,
    shipType: shipType,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  final data = purchaseResponse!.data;
  shipCache.updateShip(data.ship);
  agentCache.updateAgent(data.agent);
  return data;
}

/// Set the [flightMode] of [ship]
Future<ShipNav> setShipFlightMode(
  Api api,
  Ship ship,
  ShipNavFlightMode flightMode,
) async {
  final request = PatchShipNavRequest(flightMode: flightMode);
  final response =
      await api.fleet.patchShipNav(ship.symbol, patchShipNavRequest: request);
  ship.nav = response!.data;
  return response.data;
}

/// Navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> _navigateShip(
  Api api,
  Ship ship,
  String waypointSymbol,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypointSymbol);
  final result =
      await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
  final data = result!.data;
  ship
    ..nav = data.nav
    ..fuel = data.fuel;
  return data;
}

/// Navigate [ship] to [waypointSymbol] will retry in drift mode if
/// there is insufficient fuel.
Future<NavigateShip200ResponseData> navigateToLocalWaypoint(
  Api api,
  Ship ship,
  String waypointSymbol,
) async {
  await undockIfNeeded(api, ship);
  try {
    return await _navigateShip(api, ship, waypointSymbol);
  } on ApiException catch (e) {
    if (!isInfuficientFuelException(e)) {
      rethrow;
    }
    shipWarn(ship, 'Insufficient fuel, drifting to $waypointSymbol');
    await setShipFlightMode(api, ship, ShipNavFlightMode.DRIFT);
    return _navigateShip(api, ship, waypointSymbol);
  }
}

/// Extract resources from asteroid with [ship]
Future<ExtractResources201ResponseData> extractResources(
  Api api,
  Ship ship, {
  Survey? survey,
}) async {
  ExtractResourcesRequest? request;
  if (survey != null) {
    request = ExtractResourcesRequest(
      survey: survey,
    );
  }
  final response = await api.fleet
      .extractResources(ship.symbol, extractResourcesRequest: request);
  ship.cargo = response!.data.cargo;
  return response.data;
}

/// Deliver [units] of [tradeSymbol] to [contract]
Future<DeliverContract200ResponseData> deliverContract(
  Api api,
  Ship ship,
  Contract contract,
  String tradeSymbol,
  int units,
) async {
  final request = DeliverContractRequest(
    shipSymbol: ship.symbol,
    tradeSymbol: tradeSymbol,
    units: units,
  );
  final response = await api.contracts
      .deliverContract(contract.id, deliverContractRequest: request);
  // Does not update the contract.
  ship.cargo = response!.data.cargo;
  return response.data;
}

/// Sell [units] of [tradeSymbol] to market.
Future<SellCargo201ResponseData> sellCargo(
  Api api,
  AgentCache agentCache,
  Ship ship,
  TradeSymbol tradeSymbol,
  int units,
) async {
  final request = SellCargoRequest(
    symbol: tradeSymbol,
    units: units,
  );
  final response =
      await api.fleet.sellCargo(ship.symbol, sellCargoRequest: request);
  ship.cargo = response!.data.cargo;
  agentCache.updateAgent(response.data.agent);
  return response.data;
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
Future<void> sellAllCargoAndLog(
  Api api,
  PriceData priceData,
  TransactionLog transactions,
  AgentCache agentCache,
  Market market,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async {
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return;
  }

  await for (final response
      in sellAllCargo(api, agentCache, market, ship, where: where)) {
    final transaction = response.transaction;
    final agent = response.agent;
    logTransaction(ship, priceData, agent, transaction);
    transactions
        .log(Transaction.fromMarketTransaction(transaction, agent.credits));
  }
}

/// Buy [amountToBuy] units of [tradeSymbol] and log the transaction.
Future<SellCargo201ResponseData?> purchaseCargoAndLog(
  Api api,
  PriceData priceData,
  TransactionLog transactionLog,
  Ship ship,
  TradeSymbol tradeSymbol,
  int amountToBuy,
) async {
  // TODO(eseidel): Move trade volume and cargo space checks inside here.
  final request = PurchaseCargoRequest(
    symbol: tradeSymbol,
    units: amountToBuy,
  );
  try {
    final response = await api.fleet
        .purchaseCargo(ship.symbol, purchaseCargoRequest: request);
    final transaction = response!.data.transaction;
    // Do we need to handle transaction limits?  Callers can check before.
    // ApiException 400: {"error":{"message":"Market transaction failed.
    // Trade good REACTOR_FUSION_I has a limit of 10 units per transaction.",
    // "code":4604,"data":{"waypointSymbol":"X1-UC8-13100A","tradeSymbol":
    // "REACTOR_FUSION_I","units":60,"tradeVolume":10}}}
    final agent = response.data.agent;
    logTransaction(ship, priceData, agent, transaction);
    transactionLog.log(
      Transaction.fromMarketTransaction(
        response.data.transaction,
        agent.credits,
      ),
    );
    ship.cargo = response.data.cargo;
    return response.data;
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
  PriceData priceData,
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
  PriceData priceData,
  ShipCache shipCache,
  AgentCache agentCache,
  Ship ship,
  String shipyardSymbol,
  ShipType shipType,
) async {
  final result =
      await purchaseShip(api, shipCache, agentCache, shipyardSymbol, shipType);
  logShipyardTransaction(ship, priceData, result.agent, result.transaction);
  return result;
}

/// Refuel the ship if needed and log the transaction
Future<void> refuelIfNeededAndLog(
  Api api,
  PriceData priceData,
  TransactionLog transactionLog,
  AgentCache agentCache,
  Market market,
  Ship ship,
) async {
  if (!ship.shouldRefuel) {
    return;
  }
  const fuelSymbol = 'FUEL';
  // Ensure the fuel here is not wildly overpriced (as is sometimes the case).
  final fuelGood = market.tradeGoods.firstWhereOrNull(
    (g) => g.symbol == fuelSymbol,
  );
  if (fuelGood == null) {
    shipWarn(ship, 'Market does not sell fuel, not refueling.');
    return;
  }
  final fuelPrice = fuelGood.purchasePrice;
  final median = priceData.medianPurchasePrice(fuelSymbol);
  final markup = median != null ? fuelPrice / median : null;
  if (markup != null && markup > 2) {
    final deviation = stringForPriceDeviance(
      priceData,
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
      return;
    }
    shipWarn(
        ship,
        'Fuel is at $markupString times the median price '
        '$fuelString ($deviation), but also critically low, refueling anyway');
  }

  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  try {
    final responseWrapper = await api.fleet.refuelShip(ship.symbol);
    final response = responseWrapper!.data;
    // Does not update agent.
    ship.fuel = response.fuel;
    logTransaction(
      ship,
      priceData,
      agentCache.agent,
      response.transaction,
      transactionEmoji: '⛽',
    );
    transactionLog.log(
      Transaction.fromMarketTransaction(
        response.transaction,
        agentCache.agent.credits,
      ),
    );
    // Reset flight mode on refueling.
    if (ship.nav.flightMode != ShipNavFlightMode.CRUISE) {
      shipInfo(ship, 'Resetting flight mode to cruise');
      ship.nav = await setShipFlightMode(api, ship, ShipNavFlightMode.CRUISE);
    }
  } on ApiException catch (e) {
    // Instead of handling this exception, we could check that the market
    // sells fuel before hand, but that would be one extra request if we don't
    // have the market cached.  (We probably always have it cached...)
    if (!isMarketDoesNotSellFuelException(e)) {
      rethrow;
    }
    shipInfo(ship, 'Market does not sell fuel, not refueling.');
  }
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
  //   await refuelIfNeededAndLog(api, priceData, agent, ship);
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
  Contract contract,
) async {
  final response = await api.contracts.acceptContract(contract.id);
  logger
    ..info('Accepted: ${contractDescription(contract)}.')
    ..info(
      'received ${creditsString(contract.terms.payment.onAccepted)}',
    );
  return response!.data;
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
