import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/exceptions.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:space_traders_cli/printing.dart';

/// purchase a ship of type [shipType] at [shipyardSymbol]
Future<PurchaseShip201ResponseData> purchaseShip(
  Api api,
  ShipType shipType,
  String shipyardSymbol,
) async {
  final purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardSymbol,
    shipType: shipType,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  return purchaseResponse!.data;
}

/// Set the [flightMode] of [shipSymbol]
Future<ShipNav> setShipFlightMode(
  Api api,
  String shipSymbol,
  ShipNavFlightMode flightMode,
) async {
  final request = PatchShipNavRequest(flightMode: flightMode);
  final response =
      await api.fleet.patchShipNav(shipSymbol, patchShipNavRequest: request);
  return response!.data;
}

/// navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> navigateToLocalWaypoint(
  Api api,
  Ship ship,
  String waypointSymbol,
) async {
  try {
    final request = NavigateShipRequest(waypointSymbol: waypointSymbol);
    final result =
        await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
    return result!.data;
  } on ApiException catch (e) {
    if (!isInfuficientFuelException(e)) {
      rethrow;
    }
    shipWarn(ship, 'Insufficient fuel, drifting to $waypointSymbol');
    ship.nav =
        await setShipFlightMode(api, ship.symbol, ShipNavFlightMode.DRIFT);
    final request = NavigateShipRequest(waypointSymbol: waypointSymbol);
    final result =
        await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
    return result!.data;
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
  return response!.data;
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
  return response!.data;
}

// Future<SellCargo201ResponseData> sellItem(
//   Api api,
//   Ship ship,
//   String tradeSymbol,
//   int units,
// ) async {
//   final request = SellCargoRequest(
//     symbol: tradeSymbol,
//     units: units,
//   );
//   final response =
//       await api.fleet.sellCargo(ship.symbol, sellCargoRequest: request);
//   return response!.data;
// }

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellCargo(
  Api api,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async* {
  final marketResponse = await api.systems
      .getMarket(ship.nav.systemSymbol, ship.nav.waypointSymbol);
  final market = marketResponse!.data;

  // This should not sell anything we have a contract for.
  // We should travel first to the marketplace that has the best price for
  // the ore we have a contract for.
  for (final item in ship.cargo.inventory) {
    if (where != null && !where(item.symbol)) {
      continue;
    }
    if (!market.tradeGoods.any((g) => g.symbol == item.symbol)) {
      // shipInfo(
      //   ship,
      //   "Market at ${ship.nav.waypointSymbol} doesn't buy ${item.symbol}",
      // );
      continue;
    }
    final sellRequest = SellCargoRequest(
      symbol: item.symbol,
      units: item.units,
    );
    final sellResponse =
        await api.fleet.sellCargo(ship.symbol, sellCargoRequest: sellRequest);
    yield sellResponse!.data;
  }
}

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// Logs each transaction or "No cargo to sell" if there is no cargo.
Future<ShipCargo> sellCargoAndLog(
  Api api,
  PriceData priceData,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async {
  var newCargo = ship.cargo;
  if (ship.cargo.inventory.isEmpty) {
    shipInfo(ship, 'No cargo to sell');
    return newCargo;
  }

  await for (final response in sellCargo(api, ship, where: where)) {
    final transaction = response.transaction;
    final agent = response.agent;
    logTransaction(ship, priceData, agent, transaction);
    newCargo = response.cargo;
  }
  return newCargo;
}

/// Buy [amountToBuy] units of [tradeSymbol] and log the transaction.
Future<SellCargo201ResponseData?> purchaseCargoAndLog(
  Api api,
  PriceData priceData,
  Ship ship,
  String tradeSymbol,
  int amountToBuy,
) async {
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

/// refuel the ship if needed and log the transaction
Future<void> refuelIfNeededAndLog(
  Api api,
  PriceData priceData,
  Agent agent,
  Ship ship,
) async {
  if (!ship.shouldRefuel) {
    return;
  }
  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  try {
    final responseWrapper = await api.fleet.refuelShip(ship.symbol);
    final response = responseWrapper!.data;
    logTransaction(
      ship,
      priceData,
      agent,
      response.transaction,
      transactionEmoji: '⛽',
    );
    // Reset flight mode on refueling.
    if (ship.nav.flightMode != ShipNavFlightMode.CRUISE) {
      shipInfo(ship, 'Resetting flight mode to cruise');
      await setShipFlightMode(api, ship.symbol, ShipNavFlightMode.CRUISE);
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
    shipInfo(ship, '🛬 at ${ship.nav.waypointSymbol}');
    await api.fleet.dockShip(ship.symbol);
  }
}

/// Undock the ship if needed and log the transaction
Future<void> undockIfNeeded(Api api, Ship ship) async {
  if (ship.isDocked) {
    // Extra space after emoji is needed for windows powershell.
    shipInfo(ship, '🛰️  at ${ship.nav.waypointSymbol}');
    await api.fleet.orbitShip(ship.symbol);
  }
}

/// Navigate to the waypoint and log to the ship's log
Future<DateTime> navigateToLocalWaypointAndLog(
  Api api,
  Ship ship,
  Waypoint waypoint,
) async {
  // Should this dock and refuel and reset the flight mode if needed?
  // if (ship.shouldRefuel) {
  //   await refuelIfNeededAndLog(api, priceData, agent, ship);
  // }

  final result = await navigateToLocalWaypoint(api, ship, waypoint.symbol);
  final flightTime = result.nav.route.arrival.difference(DateTime.now());
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
    shipInfo(ship, 'Charted ${waypointDescription(waypoint)}');
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
  shipInfo(ship, 'Used Jump Gate to $systemSymbol');
  return response!.data;
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
