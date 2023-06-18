import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';

// This is for direct non-logging actions
// Functions in this file are responsible for unwrapping data from inside
// responses as well as updating the caches.
// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.

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
Future<NavigateShip200ResponseData> navigateShip(
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

/// Purchase [units] of [tradeSymbol] from market.
/// Returns the response data.
/// Throws an exception if the purchase fails.
Future<SellCargo201ResponseData> purchaseCargo(
  Api api,
  AgentCache agentCache,
  Ship ship,
  TradeSymbol tradeSymbol,
  int units,
) async {
  final request = PurchaseCargoRequest(
    symbol: tradeSymbol,
    units: units,
  );
  final response =
      await api.fleet.purchaseCargo(ship.symbol, purchaseCargoRequest: request);
  final data = response!.data;
  ship.cargo = data.cargo;
  agentCache.updateAgent(data.agent);
  return data;
}

/// Refuel [ship] at the current waypoint.
/// Returns the response data.
/// Throws an exception if the refuel fails.
Future<RefuelShip200ResponseData> refuelShip(
  Api api,
  AgentCache agentCache,
  Ship ship,
) async {
  final responseWrapper = await api.fleet.refuelShip(ship.symbol);
  final data = responseWrapper!.data;
  agentCache.updateAgent(data.agent);
  ship.fuel = data.fuel;
  return data;
}
