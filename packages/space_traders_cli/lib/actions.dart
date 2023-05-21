import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
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

/// navigate [ship] to [waypoint]
Future<NavigateShip200ResponseData> navigateTo(
  Api api,
  Ship ship,
  Waypoint waypoint,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypoint.symbol);
  final result =
      await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
  return result!.data;
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

/// Sell all cargo matching the [where] predicate.
/// If [where] is null, sell all cargo.
/// returns a stream of the sell responses.
Stream<SellCargo201ResponseData> sellCargo(
  Api api,
  Ship ship, {
  bool Function(String tradeSymbol)? where,
}) async* {
  // logCargo(ship);
  // final contractsResponse = await api.contracts.getContracts();
  // print("Contracts: ${contractsResponse!.data}");
  // final marketplaces =
  //     systemWaypoints.where((w) => w.hasMarketplace).toList();
  // printWaypoints(marketplaces);

  final marketResponse = await api.systems
      .getMarket(ship.nav.systemSymbol, ship.nav.waypointSymbol);
  final market = marketResponse!.data;
  // prettyPrintJson(market.toJson());

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
Future<void> purchaseCargoAndLog(
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
  final response =
      await api.fleet.purchaseCargo(ship.symbol, purchaseCargoRequest: request);
  final transaction = response!.data.transaction;
  final agent = response.data.agent;
  logTransaction(ship, priceData, agent, transaction);
}

/// refuel the ship if needed and log the transaction
Future<void> refuelIfNeededAndLog(
  Api api,
  PriceData priceData,
  Agent agent,
  Ship ship,
) async {
  // One fuel bought from the market is 100 units of fuel in the ship.
  // For repeated short trips, avoiding buying fuel when we're close to full.
  if (ship.fuel.current >= (ship.fuel.capacity - 100)) {
    return;
  }
  // shipInfo(ship, 'Refueling (${ship.fuel.current} / ${ship.fuel.capacity})');
  final responseWrapper = await api.fleet.refuelShip(ship.symbol);
  final response = responseWrapper!.data;
  logTransaction(
    ship,
    priceData,
    agent,
    response.transaction,
    transactionEmoji: '⛽',
  );
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
Future<DateTime> navigateToAndLog(
  Api api,
  Ship ship,
  Waypoint waypoint,
) async {
  final result = await navigateTo(api, ship, waypoint);
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
