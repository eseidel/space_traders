import 'dart:math';

import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/direct.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/printing.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

export 'package:cli/net/direct.dart';

// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.

/// Navigate [ship] to [waypointSymbol] will retry in drift mode if
/// there is insufficient fuel.
Future<NavigateShip200ResponseData> navigateToLocalWaypoint(
  Api api,
  ShipCache shipCache,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  await undockIfNeeded(api, shipCache, ship);
  if (!ship.usesFuel && ship.nav.flightMode != ShipNavFlightMode.BURN) {
    shipInfo(ship, 'Does not use fuel, setting flight mode to burn.');
    await setShipFlightMode(api, shipCache, ship, ShipNavFlightMode.BURN);
  }
  try {
    final waitUntil = await navigateShip(api, shipCache, ship, waypointSymbol);
    return waitUntil;
  } on ApiException catch (e) {
    if (!isInfuficientFuelException(e)) {
      rethrow;
    }
    shipWarn(ship, 'Insufficient fuel, drifting to $waypointSymbol');
    await setShipFlightMode(api, shipCache, ship, ShipNavFlightMode.DRIFT);
    final waitUntil = await navigateShip(api, shipCache, ship, waypointSymbol);
    return waitUntil;
  }
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellAllCargo(
  Api api,
  AgentCache agentCache,
  Market market,
  ShipCache shipCache,
  Ship ship, {
  bool Function(TradeSymbol tradeSymbol)? where,
}) async* {
  // This should not sell anything we have a contract for.
  // We should travel first to the marketplace that has the best price for
  // the ore we have a contract for.
  for (final item in ship.cargo.inventory) {
    if (where != null && !where(item.tradeSymbol)) {
      continue;
    }
    final good = market.marketTradeGood(item.tradeSymbol);
    if (good == null) {
      shipInfo(
        ship,
        "Market at ${ship.waypointSymbol} doesn't buy ${item.symbol}",
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
        shipCache,
        item.tradeSymbol,
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
  Database db,
  MarketPrices marketPrices,
  AgentCache agentCache,
  Market market,
  ShipCache shipCache,
  Ship ship,
  AccountingType accounting, {
  bool Function(TradeSymbol tradeSymbol)? where,
}) async {
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return [];
  }

  final transactions = <Transaction>[];
  await for (final response
      in sellAllCargo(api, agentCache, market, shipCache, ship, where: where)) {
    final marketTransaction = response.transaction;
    final agent = response.agent;
    logMarketTransaction(ship, marketPrices, agent, marketTransaction);
    final transaction = Transaction.fromMarketTransaction(
      marketTransaction,
      agent.credits,
      accounting,
    );
    await db.insertTransaction(transaction);
    transactions.add(transaction);
  }
  return transactions;
}

/// Jettison all cargo.
Future<void> jettisonAllCargoAndLog(
  Api api,
  ShipCache shipCache,
  Ship ship,
) async {
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to jettison');
    return;
  }

  for (final item in ship.cargo.inventory) {
    shipWarn(ship, 'Jettisoning ${item.units} ${item.symbol}');
    final response = await api.fleet.jettison(
      ship.symbol,
      jettisonRequest:
          JettisonRequest(symbol: item.tradeSymbol, units: item.units),
    );
    ship.cargo = response!.data.cargo;
    shipCache.updateShip(ship);
  }
}

/// Buy [amountToBuy] units of [tradeSymbol] and log the transaction.
Future<Transaction?> purchaseCargoAndLog(
  Api api,
  Database db,
  MarketPrices marketPrices,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
  TradeSymbol tradeSymbol,
  int amountToBuy,
  AccountingType accounting,
) async {
  // TODO(eseidel): Move trade volume and cargo space checks inside here.
  try {
    final data = await purchaseCargo(
      api,
      agentCache,
      shipCache,
      ship,
      tradeSymbol,
      amountToBuy,
    );
    // Do we need to handle transaction limits?  Callers should check before.
    // ApiException 400: {"error":{"message":"Market transaction failed.
    // Trade good REACTOR_FUSION_I has a limit of 10 units per transaction.",
    // "code":4604,"data":{"waypointSymbol":"X1-UC8-13100A","tradeSymbol":
    // "REACTOR_FUSION_I","units":60,"tradeVolume":10}}}
    final agent = data.agent;
    final marketTransaction = data.transaction;
    logMarketTransaction(ship, marketPrices, agent, marketTransaction);
    final transaction = Transaction.fromMarketTransaction(
      marketTransaction,
      agent.credits,
      accounting,
    );
    await db.insertTransaction(transaction);
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

/// Purchase a ship and log the transaction.
Future<PurchaseShip201ResponseData> purchaseShipAndLog(
  Api api,
  Database db,
  ShipCache shipCache,
  AgentCache agentCache,
  Ship ship,
  WaypointSymbol shipyardSymbol,
  ShipType shipType,
) async {
  final result =
      await purchaseShip(api, shipCache, agentCache, shipyardSymbol, shipType);
  logShipyardTransaction(ship, result.agent, result.transaction);
  shipErr(ship, 'Bought ship: ${result.ship.symbol}');
  final transaction = Transaction.fromShipyardTransaction(
    result.transaction,
    // purchaseShip updated the agentCache
    agentCache.agent.credits,
    ship.shipSymbol,
  );
  await db.insertTransaction(transaction);
  return result;
}

bool _shouldRefuelAfterCheckingPrice(
  MarketPrices marketPrices,
  Ship ship,
  int fuelPrice,
) {
  const fuelSymbol = TradeSymbol.FUEL;
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
      shipWarn(ship, 'Fuel low: ${ship.fuel.current} / ${ship.fuel.capacity}');
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

// Hack to prevent miners taking short trips from refueling constantly.
bool _shouldRefuelBasedOnUsage(Ship ship) {
  final recentFuelSpend = ship.fuel.consumed?.amount;
  // This is currently 900 * 0.2 = 180 which is medium length trip.
  final twentyPercentTank = ship.fuel.capacity * 0.2;
  final takingShortTrips =
      recentFuelSpend != null && recentFuelSpend < twentyPercentTank;
  if (ship.isMiner && takingShortTrips) {
    // If we're a miner, we should only refuel if we're below 50% fuel.
    shipDetail(
        ship,
        'Not refueling yet, last trip was short ($recentFuelSpend fuel)'
        ' and at ${(100.0 * ship.fuelPercentage).toStringAsFixed(1)}% fuel.');
    return ship.fuelPercentage < 0.5;
  }
  return true;
}

/// Refuel the ship if needed and log the transaction
Future<RefuelShip200ResponseData?> refuelIfNeededAndLog(
  Api api,
  Database db,
  MarketPrices marketPrices,
  AgentCache agentCache,
  ShipCache shipCache,
  Market market,
  Ship ship,
) async {
  if (!ship.shouldRefuel) {
    return null;
  }
  // Ensure the fuel here is not wildly overpriced (as is sometimes the case).
  final fuelGood = market.marketTradeGood(TradeSymbol.FUEL);
  if (fuelGood == null) {
    shipWarn(ship, 'Market does not sell fuel, not refueling.');
    return null;
  }
  if (!_shouldRefuelBasedOnUsage(ship)) {
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
  final data = await refuelShip(api, agentCache, shipCache, ship);
  final marketTransaction = data.transaction;
  final agent = agentCache.agent;
  logMarketTransaction(
    ship,
    marketPrices,
    agent,
    marketTransaction,
    transactionEmoji: '⛽',
  );
  final transaction = Transaction.fromMarketTransaction(
    marketTransaction,
    agent.credits,
    AccountingType.fuel,
  );
  await db.insertTransaction(transaction);
  // Reset flight mode on refueling.
  if (ship.nav.flightMode != ShipNavFlightMode.CRUISE) {
    shipInfo(ship, 'Resetting flight mode to cruise');
    await setShipFlightMode(api, shipCache, ship, ShipNavFlightMode.CRUISE);
  }
  return data;
}

/// Dock the ship if needed and log the transaction
Future<void> dockIfNeeded(Api api, ShipCache shipCache, Ship ship) async {
  if (ship.isOrbiting) {
    shipDetail(ship, '🛬 at ${ship.waypointSymbol}');
    final response = await api.fleet.dockShip(ship.symbol);
    ship.nav = response!.data.nav;
    shipCache.updateShip(ship);
  }
}

/// Undock the ship if needed and log the transaction
Future<void> undockIfNeeded(Api api, ShipCache shipCache, Ship ship) async {
  if (ship.isDocked) {
    // Extra space after emoji is needed for windows powershell.
    shipDetail(ship, '🛰️  at ${ship.waypointSymbol}');
    final response = await api.fleet.orbitShip(ship.symbol);
    ship.nav = response!.data.nav;
    shipCache.updateShip(ship);
  }
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> navigateToLocalWaypointAndLog(
  Api api,
  ShipCache shipCache,
  Ship ship,
  SystemWaypoint waypoint,
) async {
  // Should this dock and refuel and reset the flight mode if needed?
  // if (ship.shouldRefuel) {
  //   await refuelIfNeededAndLog(api, marketPrices, agent, ship);
  // }

  final result = await navigateToLocalWaypoint(
    api,
    shipCache,
    ship,
    waypoint.waypointSymbol,
  );
  final flightTime = result.nav.route.arrival.difference(DateTime.timestamp());
  if (ship.fuelPercentage < 0.5) {
    shipWarn(ship, 'Fuel low: ${ship.fuel.current} / ${ship.fuel.capacity}');
  }
  final consumedFuel = result.fuel.consumed?.amount ?? 0;
  final fuelString = consumedFuel > 0 ? ' spent $consumedFuel fuel' : '';
  shipInfo(
    ship,
    '🛫 to ${waypoint.symbol} ${waypoint.type} '
    '(${approximateDuration(flightTime)})$fuelString',
  );
  return result.nav.route.arrival;
}

/// Chart the waypoint [ship] is currently at and log.
Future<void> chartWaypointAndLog(
  Api api,
  ChartingCache chartingCache,
  Ship ship,
) async {
  try {
    final response = await api.fleet.createChart(ship.symbol);
    final waypoint = response!.data.waypoint;
    chartingCache.addWaypoint(waypoint);
    // Powershell needs the space after the emoji.
    shipInfo(ship, '🗺️  ${waypointDescription(waypoint)}');
  } on ApiException catch (e) {
    if (!isWaypointAlreadyChartedException(e)) {
      rethrow;
    }
    shipWarn(ship, '${ship.waypointSymbol} was already charted');
  }
}

Future<JumpShip200ResponseData> _useJumpGateAndLogInner(
  Api api,
  ShipCache shipCache,
  Ship ship,
  SystemSymbol systemSymbol,
) async {
  shipDetail(ship, 'Jump from ${ship.nav.systemSymbol} to $systemSymbol');
  final jumpShipRequest = JumpShipRequest(systemSymbol: systemSymbol.system);
  final response =
      await api.fleet.jumpShip(ship.symbol, jumpShipRequest: jumpShipRequest);
  ship
    ..nav = response!.data.nav
    ..cooldown = response.data.cooldown;
  shipCache.updateShip(ship);
  // shipDetail(ship, 'Used Jump Gate to $systemSymbol');
  return response.data;
}

/// Use the jump gate to travel to [systemSymbol] and log.
Future<JumpShip200ResponseData> useJumpGateAndLog(
  Api api,
  ShipCache shipCache,
  Ship ship,
  SystemSymbol systemSymbol,
) async {
  try {
    final waitUntil =
        await _useJumpGateAndLogInner(api, shipCache, ship, systemSymbol);
    return waitUntil;
  } on ApiException catch (e) {
    if (!isShipNotInOrbitException(e)) {
      rethrow;
    }
    // This is an error in the surrounding code (or possibly our cached state).
    shipWarn(ship, 'Ship tried to jump while not in orbit?!');
    final waitUntil =
        await _useJumpGateAndLogInner(api, shipCache, ship, systemSymbol);
    return waitUntil;
  }
}

/// Negotiate a contract for [ship] and log.
Future<Contract> negotiateContractAndLog(
  Api api,
  Ship ship,
  ShipCache shipCache,
  ContractCache contractCache,
) async {
  await dockIfNeeded(api, shipCache, ship);
  final response = await api.fleet.negotiateContract(ship.symbol);
  final contractData = response!.data;
  final contract = contractData.contract;
  contractCache.updateContract(contract);
  shipInfo(ship, 'Negotiated contract: ${contractDescription(contract)}');
  return contract;
}

/// Accept [contract] and log.
Future<AcceptContract200ResponseData> acceptContractAndLog(
  Api api,
  Database db,
  ContractCache contractCache,
  AgentCache agentCache,
  Ship ship,
  Contract contract,
) async {
  final response = await api.contracts.acceptContract(contract.id);
  final data = response!.data;
  agentCache.agent = data.agent;
  contractCache.updateContract(data.contract);
  shipInfo(ship, 'Accepted: ${contractDescription(contract)}.');
  shipInfo(
    ship,
    'received ${creditsString(contract.terms.payment.onAccepted)}',
  );

  final contactTransaction = ContractTransaction.accept(
    contract: contract,
    shipSymbol: ship.shipSymbol,
    waypointSymbol: ship.waypointSymbol,
    timestamp: DateTime.timestamp(),
  );
  final transaction = Transaction.fromContractTransaction(
    contactTransaction,
    agentCache.agent.credits,
  );
  await db.insertTransaction(transaction);

  return data;
}

/// Install a mount on a ship from its cargo.
Future<InstallMount201ResponseData> installMountAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.installMount(
    ship.symbol,
    installMountRequest: InstallMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  agentCache.agent = data.agent;
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  shipCache.updateShip(ship);
  logShipModificationTransaction(ship, agentCache.agent, data.transaction);
  final transaction = Transaction.fromShipModificationTransaction(
    data.transaction,
    agentCache.agent.credits,
  );
  await db.insertTransaction(transaction);
  return data;
}

/// Remove mount from a ship's mount list (but not cargo).
Future<RemoveMount201ResponseData> removeMountAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.removeMount(
    ship.symbol,
    removeMountRequest: RemoveMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  agentCache.agent = data.agent;
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  shipCache.updateShip(ship);
  logShipModificationTransaction(ship, agentCache.agent, data.transaction);
  final transaction = Transaction.fromShipModificationTransaction(
    data.transaction,
    agentCache.agent.credits,
  );
  await db.insertTransaction(transaction);
  return data;
}

/// Transfer cargo between two ships.
Future<Jettison200ResponseData> transferCargoAndLog(
  Api api,
  ShipCache cache, {
  required Ship from,
  required Ship to,
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = TransferCargoRequest(
    shipSymbol: to.symbol,
    tradeSymbol: tradeSymbol,
    units: units,
  );
  final response = await api.fleet.transferCargo(
    from.symbol,
    transferCargoRequest: request,
  );
  // On failure:
  // ApiException 400: {"error":{"message":
  // "Failed to update ship cargo. Ship ESEIDEL-1 cargo does not contain 1
  // unit(s) of MOUNT_MINING_LASER_II. Ship has 0 unit(s) of
  // MOUNT_MINING_LASER_II.","code":4219,"data":{"shipSymbol":"ESEIDEL-1",
  // "tradeSymbol":"MOUNT_MINING_LASER_II","cargoUnits":0,"unitsToRemove":1}}}

  final data = response!.data;
  from.cargo = data.cargo;
  to.updateCacheWithAddedCargo(tradeSymbol, units);
  cache
    ..updateShip(from)
    ..updateShip(to);
  shipInfo(
      from,
      'Transferred $units $tradeSymbol from ${from.symbol} to '
      '${to.symbol}');
  return data;
}

/// Record the given surveys.
void recordSurveys(
  Database db,
  List<Survey> surveys, {
  DateTime Function() getNow = defaultGetNow,
}) {
  final now = getNow();
  for (final survey in surveys) {
    final historicalSurvey = HistoricalSurvey(
      survey: survey,
      timestamp: now,
      exhausted: false,
    );
    db.insertSurvey(historicalSurvey);
  }
}

/// Record the survey and log.
Future<CreateSurvey201ResponseData> surveyAndLog(
  Api api,
  Database db,
  ShipCache shipCache,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final outer = await api.fleet.createSurvey(ship.symbol);
  final response = outer!.data;
  ship.cooldown = response.cooldown;
  shipCache.updateShip(ship);
  final count = response.surveys.length;
  shipInfo(ship, '🔭 ${count}x at ${ship.waypointSymbol}');
  recordSurveys(db, response.surveys, getNow: getNow);
  return response;
}
