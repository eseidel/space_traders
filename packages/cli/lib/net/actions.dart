import 'dart:math';

import 'package:cli/behavior/job.dart';
import 'package:cli/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/logic/printing.dart';
import 'package:cli/net/direct.dart';
import 'package:cli/net/exceptions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

export 'package:cli/net/direct.dart';

// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.

bool _canCruiseTo(
  SystemsCache systemsCache,
  Ship ship,
  WaypointSymbol waypointSymbol,
) {
  if (!ship.usesFuel) {
    return true;
  }
  final start = systemsCache.waypoint(ship.waypointSymbol);
  final end = systemsCache.waypoint(waypointSymbol);
  final distance = start.distanceTo(end);
  final expectedFuel = fuelUsedByDistance(distance, ShipNavFlightMode.CRUISE);
  // Use > and a buffer (10) to avoid ever having zero fuel.
  return ship.fuel.current > expectedFuel + 10;
}

/// Navigate [ship] to [waypointSymbol] will retry in drift mode if
/// there is insufficient fuel.
Future<NavigateShip200ResponseData> navigateToLocalWaypoint(
  Database db,
  Api api,
  SystemsCache systemsCache,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  await undockIfNeeded(db, api, ship);

  final canCruise = _canCruiseTo(systemsCache, ship, waypointSymbol);
  final flightMode =
      canCruise ? ShipNavFlightMode.CRUISE : ShipNavFlightMode.DRIFT;
  await setShipFlightModeIfNeeded(db, api, ship, flightMode);
  if (!canCruise) {
    shipErr(ship, 'Insufficient fuel, drifting to $waypointSymbol');
  }

  try {
    final data = await navigateShip(db, api, ship, waypointSymbol);
    recordEvents(db, ship, data.events);
    return data;
  } on ApiException catch (e) {
    if (!isInsufficientFuelException(e)) {
      rethrow;
    }
    shipErr(ship, 'Insufficient fuel, drifting to $waypointSymbol');
    await setShipFlightMode(db, api, ship, ShipNavFlightMode.DRIFT);
    final data = await navigateShip(db, api, ship, waypointSymbol);
    recordEvents(db, ship, data.events);
    return data;
  }
}

/// Navigate [ship] to [waypointSymbol] will retry in drift mode if
/// there is insufficient fuel.
Future<WarpShip200ResponseData> warpToWaypoint(
  Database db,
  Api api,
  SystemsCache systemsCache,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  await undockIfNeeded(db, api, ship);
  final data = await warpShip(db, api, ship, waypointSymbol);
  return data;
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellAllCargo(
  Database db,
  Api api,
  AgentCache agentCache,
  Market market,
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
    // TODO(eseidel): This may be wrong if the market was passed in without
    // full data (e.g. cached from when a ship wasn't there).
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
        db,
        api,
        agentCache,
        ship,
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
  MarketPriceSnapshot marketPrices,
  AgentCache agentCache,
  Market market,
  Ship ship,
  AccountingType accountingType, {
  bool Function(TradeSymbol tradeSymbol)? where,
}) async {
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return [];
  }

  final transactions = <Transaction>[];
  await for (final response in sellAllCargo(
    db,
    api,
    agentCache,
    market,
    ship,
    where: where,
  )) {
    final marketTransaction = response.transaction;
    final agent = Agent.fromOpenApi(response.agent);
    final median = marketPrices.medianSellPrice(
      marketTransaction.tradeSymbolObject,
    );
    logMarketTransaction(ship, agent, marketTransaction, medianPrice: median);
    final transaction = Transaction.fromMarketTransaction(
      marketTransaction,
      agent.credits,
      accountingType,
    );
    await db.insertTransaction(transaction);
    transactions.add(transaction);
  }
  return transactions;
}

/// Jettison a specific cargo item.
Future<void> jettisonCargoAndLog(
  Database db,
  Api api,
  Ship ship,
  // This could be a tradeSymbol, but using the item seems less error prone?
  ShipCargoItem item,
) async {
  shipWarn(ship, 'Jettisoning ${item.units} ${item.symbol}');
  final response = await api.fleet.jettison(
    ship.symbol.symbol,
    jettisonRequest: JettisonRequest(
      symbol: item.tradeSymbol,
      units: item.units,
    ),
  );
  ship.cargo = response!.data.cargo;
  await db.upsertShip(ship);
}

/// Buy [amountToBuy] units of [tradeSymbol] and log the transaction.
Future<Transaction?> purchaseCargoAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  TradeSymbol tradeSymbol,
  AccountingType accounting, {
  required int amountToBuy,
  required int? medianPrice,
}) async {
  // TODO(eseidel): Move trade volume and cargo space checks inside here.
  try {
    final data = await purchaseCargo(
      db,
      api,
      agentCache,
      ship,
      tradeSymbol,
      amountToBuy,
    );
    // Do we need to handle transaction limits?  Callers should check before.
    // ApiException 400: {"error":{"message":"Market transaction failed.
    // Trade good REACTOR_FUSION_I has a limit of 10 units per transaction.",
    // "code":4604,"data":{"waypointSymbol":"X1-UC8-13100A","tradeSymbol":
    // "REACTOR_FUSION_I","units":60,"tradeVolume":10}}}
    final agent = Agent.fromOpenApi(data.agent);
    final marketTransaction = data.transaction;
    logMarketTransaction(
      ship,
      agent,
      marketTransaction,
      medianPrice: medianPrice,
    );
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
    throw JobException(
      'Purchase of $amountToBuy $tradeSymbol failed. '
      'Insufficient credits.',
      const Duration(minutes: 1),
    );
  }
}

/// Purchase a ship and log the transaction.
Future<PurchaseShip201ResponseData> purchaseShipAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  WaypointSymbol shipyardSymbol,
  ShipType shipType,
) async {
  final result = await purchaseShip(
    db,
    api,
    agentCache,
    shipyardSymbol,
    shipType,
  );
  final agent = Agent.fromOpenApi(result.agent);
  logShipyardTransaction(ship, agent, result.transaction);
  shipErr(ship, 'Bought ship: ${result.ship.symbol}');
  final transaction = Transaction.fromShipyardTransaction(
    result.transaction,
    // purchaseShip updated the agentCache
    agentCache.agent.credits,
    ship.symbol,
  );
  await db.insertTransaction(transaction);
  return result;
}

/// Scrap the ship and log the transaction.
Future<ScrapShip200ResponseData> scrapShipAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
) async {
  final result = await scrapShip(db, api, agentCache, ship.symbol);
  final agent = Agent.fromOpenApi(result.agent);
  logScrapTransaction(ship, agent, result.transaction);
  shipErr(
    ship,
    'Scrapped ship for ${creditsString(result.transaction.totalPrice)}',
  );
  final transaction = Transaction.fromScrapTransaction(
    result.transaction,
    // scrapShip updated the agent cache.
    agentCache.agent.credits,
    ship.symbol,
  );
  await db.insertTransaction(transaction);
  return result;
}

bool _shouldRefuelAfterCheckingPrice(
  Ship ship, {
  required TradeSymbol fuelSymbol,
  required int price,
  required int? median,
}) {
  final markup = median != null ? price / median : null;
  if (markup != null && markup > config.fuelWarningMarkup) {
    final deviation = stringForPriceDeviance(
      fuelSymbol,
      price: price,
      median: median,
      MarketTransactionTypeEnum.PURCHASE,
    );
    final fuelString = creditsString(price);

    final fuelPercent = ship.fuel.current / ship.fuel.capacity;
    if (fuelPercent < config.fuelCriticalThreshold) {
      shipWarn(ship, 'Fuel low: ${ship.fuel.current} / ${ship.fuel.capacity}');
    }
    final markupString = markup.toStringAsFixed(1);
    // The really bonkers prices are 100x median.
    if (markup > config.fuelMaxMarkup ||
        fuelPercent > config.fuelCriticalThreshold) {
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
      '$fuelString ($deviation), but also critically low, refueling anyway',
    );
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
    shipInfo(
      ship,
      'Not refueling yet, last trip was short ($recentFuelSpend fuel)'
      ' and at ${(100.0 * ship.fuelPercentage).toStringAsFixed(1)}% fuel.',
    );
    return ship.fuelPercentage < 0.5;
  }
  return true;
}

bool _shouldRefuelBasedOnCapacity(Ship ship) {
  final fuel = ship.fuel;
  if (fuel.capacity == 0) {
    return false;
  }
  // We used to avoid spillover here, but the route planner doesn't know about
  // partial fuel tanks, so until we fix that, we always refill to full.
  return fuel.current < fuel.capacity;
}

/// Refuel the ship if needed and log the transaction
Future<RefuelShip200ResponseData?> refuelIfNeededAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Market market,
  Ship ship, {
  required int? medianFuelPurchasePrice,
}) async {
  if (!_shouldRefuelBasedOnCapacity(ship)) {
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
    ship,
    fuelSymbol: fuelGood.symbol,
    price: fuelGood.purchasePrice,
    median: medianFuelPurchasePrice,
  )) {
    return null;
  }
  return refuelAndLog(
    api,
    db,
    agentCache,
    ship,
    medianFuelPurchasePrice: medianFuelPurchasePrice,
  );
}

/// Refuel the ship and log the transaction.
Future<RefuelShip200ResponseData?> refuelAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship, {
  required int? medianFuelPurchasePrice,
  bool fromCargo = false,
}) async {
  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  final data = await refuelShip(
    db,
    api,
    agentCache,
    ship,
    fromCargo: fromCargo,
  );
  final marketTransaction = data.transaction;
  final agent = agentCache.agent;
  logMarketTransaction(
    ship,
    agent,
    marketTransaction,
    medianPrice: medianFuelPurchasePrice,
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
    await setShipFlightMode(db, api, ship, ShipNavFlightMode.CRUISE);
  }
  return data;
}

/// Dock the ship if needed and log the transaction
Future<void> dockIfNeeded(Database db, Api api, Ship ship) async {
  if (ship.isOrbiting) {
    shipDetail(ship, '🛬 at ${ship.waypointSymbol}');
    final response = await api.fleet.dockShip(ship.symbol.symbol);
    ship.nav = response!.data.nav;
    await db.upsertShip(ship);
  }
}

/// Undock the ship if needed and log the transaction
Future<void> undockIfNeeded(Database db, Api api, Ship ship) async {
  if (ship.isDocked) {
    // Extra space after emoji is needed for windows powershell.
    shipDetail(ship, '🛰️  at ${ship.waypointSymbol}');
    final response = await api.fleet.orbitShip(ship.symbol.symbol);
    ship.nav = response!.data.nav;
    await db.upsertShip(ship);
  }
}

void _checkFlightTime(
  Duration flightTime,
  Ship ship,
  NavigateShip200ResponseData result,
) {
  final route = result.nav.route;
  final expectedFlightTime = Duration(
    seconds: flightTimeByDistanceAndSpeed(
      distance: route.distance,
      shipSpeed: ship.engine.speed,
      flightMode: ship.nav.flightMode,
    ),
  );
  final delta = (flightTime - expectedFlightTime).inSeconds.abs();
  // The server seems to differ in its total time.  Maybe our algorithm
  // is wrong to use floor() and we should round?
  if (delta > 1) {
    shipWarn(
      ship,
      'Flight time ${durationString(flightTime)} '
      'does not match predicted ${durationString(expectedFlightTime)} '
      'speed: ${ship.engine.speed} mode: ${ship.nav.flightMode} '
      'distance: ${route.distance} engine: ${ship.engine.condition} '
      'frame: ${ship.frame.condition} reactor: ${ship.reactor.condition}',
    );
  }
}

void _checkFuelUsage(Ship ship, NavigateShip200ResponseData result) {
  final route = result.nav.route;
  final expectedFuel =
      ship.usesFuel
          ? fuelUsedByDistance(route.distance, ship.nav.flightMode)
          : 0;
  final delta = (result.fuel.consumed!.amount - expectedFuel).abs();
  if (delta > 1) {
    shipWarn(
      ship,
      'Fuel usage ${result.fuel.consumed!.amount} '
      'does not match predicted $expectedFuel '
      'mode: ${ship.nav.flightMode} '
      'distance: ${route.distance}',
    );
  }
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> navigateToLocalWaypointAndLog(
  Database db,
  Api api,
  SystemsCache systemsCache,
  Ship ship,
  SystemWaypoint waypoint,
) async {
  final result = await navigateToLocalWaypoint(
    db,
    api,
    systemsCache,
    ship,
    waypoint.symbol,
  );
  final flightTime = result.nav.route.duration;
  final consumedFuel = result.fuel.consumed?.amount ?? 0;
  final fuelString = consumedFuel > 0 ? ' spent $consumedFuel fuel' : '';
  shipInfo(
    ship,
    '🛫 to ${waypoint.symbol} ${waypoint.type} '
    '(${approximateDuration(flightTime)})$fuelString',
  );
  _checkFlightTime(flightTime, ship, result);
  _checkFuelUsage(ship, result);
  return result.nav.route.arrival;
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> warpToWaypointAndLog(
  Database db,
  Api api,
  SystemsCache systemsCache,
  Ship ship,
  SystemWaypoint waypoint,
) async {
  final result = await warpToWaypoint(
    db,
    api,
    systemsCache,
    ship,
    waypoint.symbol,
  );
  final flightTime = result.nav.route.duration;
  final consumedFuel = result.fuel.consumed?.amount ?? 0;
  final fuelString = consumedFuel > 0 ? ' spent $consumedFuel fuel' : '';
  shipErr(
    ship,
    '🛫 to ${waypoint.symbol} ${waypoint.type} '
    '(${approximateDuration(flightTime)})$fuelString',
  );
  // TODO(eseidel): Fix to use warp.
  // _checkFlightTime(flightTime, ship, result);
  // _checkFuelUsage(ship, result);
  return result.nav.route.arrival;
}

/// Chart the waypoint [ship] is currently at and log.
Future<void> chartWaypointAndLog(
  Api api,
  Database db,
  ChartingCache chartingCache,
  WaypointTraitCache waypointTraitCache,
  Ship ship,
) async {
  try {
    final response = await api.fleet.createChart(ship.symbol.symbol);
    final openapiWaypoint = response!.data.waypoint;
    final waypoint = Waypoint.fromOpenApi(openapiWaypoint);
    await ChartingCache.addWaypoint(db, waypoint);
    await waypointTraitCache.addAll(waypoint.traits);
    // Powershell needs the space after the emoji.
    shipInfo(ship, '🗺️  ${waypointDescription(waypoint)}');
  } on ApiException catch (e) {
    if (!isWaypointAlreadyChartedException(e)) {
      rethrow;
    }
    shipWarn(ship, '${ship.waypointSymbol} was already charted');
    // Our chart was likely out of date, so force an update.
    await WaypointCache.forceUpdateChart(api, db, ship.waypointSymbol);
  }
}

/// Use the jump gate to travel to systemSymbol and log.
Future<JumpShip200ResponseData> useJumpGateAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  WaypointSymbol destination, {
  required int? medianAntimatterPrice,
}) async {
  // Using a jump gate requires us to be in orbit.
  await undockIfNeeded(db, api, ship);

  final destinationSystem = destination.system;
  shipDetail(ship, 'Jump from ${ship.nav.systemSymbol} to $destinationSystem');
  final jumpShipRequest = JumpShipRequest(waypointSymbol: destination.waypoint);
  final response = await api.fleet.jumpShip(
    ship.symbol.symbol,
    jumpShipRequest: jumpShipRequest,
  );
  ship
    ..nav = response!.data.nav
    ..cooldown = response.data.cooldown;
  await db.upsertShip(ship);

  final data = response.data;
  final marketTransaction = data.transaction;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));

  final agent = agentCache.agent;
  logMarketTransaction(
    ship,
    agent,
    marketTransaction,
    medianPrice: medianAntimatterPrice,
    transactionEmoji: '☢️',
  );
  final transaction = Transaction.fromMarketTransaction(
    marketTransaction,
    agent.credits,
    AccountingType.fuel,
  );
  await db.insertTransaction(transaction);

  shipInfo(ship, 'Used Jump Gate to $destinationSystem');
  return response.data;
}

/// Negotiate a contract for [ship] and log.
Future<Contract> negotiateContractAndLog(
  Database db,
  Api api,
  Ship ship,
) async {
  await dockIfNeeded(db, api, ship);
  final response = await api.fleet.negotiateContract(ship.symbol.symbol);
  final contractData = response!.data;
  final contract = Contract.fromOpenApi(
    contractData.contract,
    DateTime.timestamp(),
  );
  await db.upsertContract(contract);
  shipInfo(ship, 'Negotiated contract: ${contractDescription(contract)}');
  return contract;
}

/// Accept [contract] and log.
Future<AcceptContract200ResponseData> acceptContractAndLog(
  Api api,
  Database db,
  AgentCache agentCache,
  Ship ship,
  Contract contract,
) async {
  final response = await api.contracts.acceptContract(contract.id);
  final data = response!.data;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  await db.upsertContract(
    Contract.fromOpenApi(data.contract, DateTime.timestamp()),
  );
  shipInfo(ship, 'Accepted: ${contractDescription(contract)}.');
  shipInfo(
    ship,
    'received ${creditsString(contract.terms.payment.onAccepted)}',
  );

  final contactTransaction = ContractTransaction.accept(
    contract: contract,
    shipSymbol: ship.symbol,
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
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.installMount(
    ship.symbol.symbol,
    installMountRequest: InstallMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  await db.upsertShip(ship);
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
  Ship ship,
  ShipMountSymbolEnum tradeSymbol,
) async {
  final response = await api.fleet.removeMount(
    ship.symbol.symbol,
    removeMountRequest: RemoveMountRequest(symbol: tradeSymbol.value),
  );
  final data = response!.data;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  ship
    ..cargo = data.cargo
    ..mounts = data.mounts;
  await db.upsertShip(ship);
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
  Database db,
  Api api, {
  required Ship from,
  required Ship to,
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = TransferCargoRequest(
    shipSymbol: to.symbol.symbol,
    tradeSymbol: tradeSymbol,
    units: units,
  );
  final response = await api.fleet.transferCargo(
    from.symbol.symbol,
    transferCargoRequest: request,
  );
  // On failure:
  // ApiException 400: {"error":{"message":
  // "Failed to update ship cargo. Ship ESEIDEL-1 cargo does not contain 1
  // unit(s) of MOUNT_MINING_LASER_II. Ship has 0 unit(s) of
  // MOUNT_MINING_LASER_II.","code":4219,"data":{"shipSymbol":"ESEIDEL-1",
  // "tradeSymbol":"MOUNT_MINING_LASER_II","cargoUnits":0,"unitsToRemove":1}}}

  final data = response!.data;
  final good = from.cargo.cargoItem(tradeSymbol)!;
  from.cargo = data.cargo;
  to.updateCacheWithAddedCargo(
    tradeSymbol: tradeSymbol,
    name: good.name,
    description: good.description,
    units: units,
  );
  await db.upsertShip(from);
  await db.upsertShip(to);
  shipDetail(
    from,
    'Transferred $units $tradeSymbol from ${from.symbol} to '
    '${to.symbol}',
  );
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
  Database db,
  Api api,
  Ship ship, {
  DateTime Function() getNow = defaultGetNow,
}) async {
  final outer = await api.fleet.createSurvey(ship.symbol.symbol);
  final response = outer!.data;
  ship.cooldown = response.cooldown;
  await db.upsertShip(ship);
  final count = response.surveys.length;
  shipDetail(ship, '🔭 ${count}x at ${ship.waypointSymbol}');
  recordSurveys(db, response.surveys, getNow: getNow);
  return response;
}

/// Set the [flightMode] of [ship] if it is not already set to [flightMode]
Future<void> setShipFlightModeIfNeeded(
  Database db,
  Api api,
  Ship ship,
  ShipNavFlightMode flightMode,
) async {
  if (ship.nav.flightMode == flightMode) {
    return;
  }
  shipInfo(ship, 'Setting flightMode to $flightMode');
  await setShipFlightMode(db, api, ship, flightMode);
}
