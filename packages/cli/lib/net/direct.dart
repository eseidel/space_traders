import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/contract_snapshot.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:db/db.dart';
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
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
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

/// Siphon resources from gas giant with [ship]
Future<SiphonResources201ResponseData> siphonResources(
  Api api,
  Ship ship,
  ShipCache shipCache,
) async {
  final response = await api.fleet.siphonResources(ship.symbol);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  shipCache.updateShip(ship);
  return response.data;
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
  Database db,
  Api api,
  Ship ship,
  ShipCache shipCache,
  ContractSnapshot contractSnapshot,
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
  await db.upsertContract(
    Contract.fromOpenApi(data.contract, DateTime.timestamp()),
  );
  ship.cargo = data.cargo;
  shipCache.updateShip(ship);
  return data;
}

/// Deliver [units] of [tradeSymbol] to [construction]
Future<SupplyConstruction201ResponseData> supplyConstruction(
  Api api,
  Ship ship,
  ShipCache shipCache,
  ConstructionCache constructionCache,
  Construction construction, {
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = SupplyConstructionRequest(
    shipSymbol: ship.symbol,
    tradeSymbol: tradeSymbol.value,
    units: units,
  );
  final response = await api.systems.supplyConstruction(
    construction.waypointSymbol.systemString,
    construction.waypointSymbol.waypoint,
    supplyConstructionRequest: request,
  );
  final data = response!.data;
  await constructionCache.updateConstruction(
    construction.waypointSymbol,
    data.construction,
  );
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
  final data = response!.data;
  ship.cargo = data.cargo;
  shipCache.updateShip(ship);
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  return data;
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
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Refuel [ship] at the current waypoint.
/// Returns the response data.
/// Throws an exception if the refuel fails.
Future<RefuelShip200ResponseData> refuelShip(
  Api api,
  AgentCache agentCache,
  ShipCache shipCache,
  Ship ship,
) async {
  // We used to have logic to avoid filling to full, but our route planner
  // doesn't account for non-full tanks, so for now we just always
  // refill to full.
  final responseWrapper = await api.fleet.refuelShip(ship.symbol);
  final data = responseWrapper!.data;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  ship.fuel = data.fuel;
  shipCache.updateShip(ship);
  return data;
}
