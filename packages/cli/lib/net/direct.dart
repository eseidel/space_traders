import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/contract_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:types/types.dart';

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
  WaypointSymbol shipyardSymbol,
  ShipType shipType,
) async {
  final purchaseShipRequest = PurchaseShipRequest(
    waypointSymbol: shipyardSymbol.waypoint,
    shipType: shipType,
  );
  final purchaseResponse =
      await api.fleet.purchaseShip(purchaseShipRequest: purchaseShipRequest);
  final data = purchaseResponse!.data;
  // Add the new ship to our cache.
  shipCache.updateShip(data.ship);
  agentCache.agent = data.agent;
  return data;
}

/// Set the [flightMode] of [ship]
Future<ShipNav> setShipFlightMode(
  Api api,
  ShipCache shipCache,
  Ship ship,
  ShipNavFlightMode flightMode,
) async {
  final request = PatchShipNavRequest(flightMode: flightMode);
  final response =
      await api.fleet.patchShipNav(ship.symbol, patchShipNavRequest: request);
  ship.nav = response!.data;
  shipCache.updateShip(ship);
  return response.data;
}

/// Navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> navigateShip(
  Api api,
  ShipCache shipCache,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypointSymbol.waypoint);
  final result =
      await api.fleet.navigateShip(ship.symbol, navigateShipRequest: request);
  final data = result!.data;
  ship
    ..nav = data.nav
    ..fuel = data.fuel;
  shipCache.updateShip(ship);
  return data;
}

/// Extract resources from asteroid with [ship]
/// Does not use a survey.
Future<ExtractResources201ResponseData> extractResources(
  Api api,
  Ship ship,
  ShipCache shipCache,
) async {
  final response = await api.fleet.extractResources(ship.symbol);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  shipCache.updateShip(ship);
  return response.data;
}

/// Extract resources from asteroid with [ship]
/// Uses a survey.
Future<ExtractResources201ResponseData> extractResourcesWithSurvey(
  Api api,
  Ship ship,
  ShipCache shipCache,
  Survey survey,
) async {
  final response =
      await api.fleet.extractResourcesWithSurvey(ship.symbol, survey: survey);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  shipCache.updateShip(ship);
  return response.data;
}

/// Deliver [units] of [tradeSymbol] to [contract]
Future<DeliverContract200ResponseData> deliverContract(
  Api api,
  Ship ship,
  ShipCache shipCache,
  ContractCache contractCache,
  Contract contract, {
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = DeliverContractRequest(
    shipSymbol: ship.symbol,
    tradeSymbol: tradeSymbol.value,
    units: units,
  );
  final response = await api.contracts
      .deliverContract(contract.id, deliverContractRequest: request);
  final data = response!.data;
  contractCache.updateContract(data.contract);
  ship.cargo = data.cargo;
  shipCache.updateShip(ship);
  return data;
}

/// Sell [units] of [tradeSymbol] to market.
Future<SellCargo201ResponseData> sellCargo(
  Api api,
  AgentCache agentCache,
  Ship ship,
  ShipCache shipCache,
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
  shipCache.updateShip(ship);
  agentCache.agent = response.data.agent;
  return response.data;
}

/// Purchase [units] of [tradeSymbol] from market.
/// Returns the response data.
/// Throws an exception if the purchase fails.
Future<SellCargo201ResponseData> purchaseCargo(
  Api api,
  AgentCache agentCache,
  ShipCache shipCache,
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
  shipCache.updateShip(ship);
  agentCache.agent = data.agent;
  return data;
}

/// Refuel [ship] at the current waypoint.
/// Returns the response data.
/// Throws an exception if the refuel fails.
Future<RefuelShip200ResponseData> refuelShip(
  Api api,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship, {
  bool topUp = false,
}) async {
  RefuelShipRequest? refuelShipRequest;
  if (!topUp) {
    // If we're not topping up, round down to the closest unit.
    // units needed is specified in ship fuel units, but we are actually
    // charged in market units.  One market unit = 100 ship fuel units.
    // So we round to the closest 100.
    // Note Ship.shouldRefuel will only return true if the ship needs
    // more than 100 units of fuel which works out nicely with this logic
    // to prevent ships from constantly trying to refuel but failing to.
    final unitsNeeded = (ship.fuelUnitsNeeded ~/ 100) * 100;
    if (unitsNeeded > 0) {
      refuelShipRequest = RefuelShipRequest(units: unitsNeeded);
    } else {
      // We were asked to refuel with topUp = false, but we don't need fuel.
      throw StateError(
        'refuelShip called with topUp = false and < 100 fuel needed',
      );
    }
  }
  final responseWrapper = await api.fleet
      .refuelShip(ship.symbol, refuelShipRequest: refuelShipRequest);
  final data = responseWrapper!.data;
  agentCache.agent = data.agent;
  ship.fuel = data.fuel;
  shipCache.updateShip(ship);
  return data;
}
