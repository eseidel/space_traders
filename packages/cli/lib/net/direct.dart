import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/nav/route.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

// This is for direct non-logging actions
// Functions in this file are responsible for unwrapping data from inside
// responses as well as updating the caches.
// Importantly, these actions *should* modify the state objects passed in
// e.g. if it docks the ship, it should update the ship's nav object.

/// Purchase a ship of type [shipType] at [shipyardSymbol]
Future<PurchaseShip201ResponseData> purchaseShip(
  Database db,
  Api api,
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
  await db.upsertShip(data.ship);
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Set the [flightMode] of [ship]
Future<ShipNav> setShipFlightMode(
  Database db,
  Api api,
  Ship ship,
  ShipNavFlightMode flightMode,
) async {
  final request = PatchShipNavRequest(flightMode: flightMode);
  final response =
      await api.fleet.patchShipNav(ship.symbol, patchShipNavRequest: request);
  ship.nav = response!.data;
  await db.upsertShip(ship);
  return response.data;
}

/// Navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> navigateShip(
  Database db,
  Api api,
  Ship ship,
  WaypointSymbol waypointSymbol, {
  TravelMethod travelType = TravelMethod.navigate,
}) async {
  final request = NavigateShipRequest(waypointSymbol: waypointSymbol.waypoint);
  final method = travelType == TravelMethod.warp
      ? api.fleet.warpShip
      : api.fleet.navigateShip;
  final result = await method(ship.symbol, navigateShipRequest: request);
  final data = result!.data;
  ship
    ..nav = data.nav
    ..fuel = data.fuel;
  await db.upsertShip(ship);
  return data;
}

/// Siphon resources from gas giant with [ship]
Future<SiphonResources201ResponseData> siphonResources(
  Database db,
  Api api,
  Ship ship,
) async {
  final response = await api.fleet.siphonResources(ship.symbol);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  await db.upsertShip(ship);
  return response.data;
}

/// Extract resources from asteroid with [ship]
/// Does not use a survey.
Future<ExtractResources201ResponseData> extractResources(
  Database db,
  Api api,
  Ship ship,
) async {
  final response = await api.fleet.extractResources(ship.symbol);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  await db.upsertShip(ship);
  return response.data;
}

/// Extract resources from asteroid with [ship]
/// Uses a survey.
Future<ExtractResources201ResponseData> extractResourcesWithSurvey(
  Database db,
  Api api,
  Ship ship,
  Survey survey,
) async {
  final response =
      await api.fleet.extractResourcesWithSurvey(ship.symbol, survey: survey);
  ship
    ..cargo = response!.data.cargo
    ..cooldown = response.data.cooldown;
  await db.upsertShip(ship);
  return response.data;
}

/// Deliver [units] of [tradeSymbol] to [contract]
Future<DeliverContract200ResponseData> deliverContract(
  Database db,
  Api api,
  Ship ship,
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
  await db.upsertShip(ship);
  return data;
}

/// Deliver [units] of [tradeSymbol] to [construction]
Future<SupplyConstruction201ResponseData> supplyConstruction(
  Database db,
  Api api,
  Ship ship,
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
  await db.upsertShip(ship);
  return data;
}

/// Sell [units] of [tradeSymbol] to market.
Future<SellCargo201ResponseData> sellCargo(
  Database db,
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
  final data = response!.data;
  ship.cargo = data.cargo;
  await db.upsertShip(ship);
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Purchase [units] of [tradeSymbol] from market.
/// Returns the response data.
/// Throws an exception if the purchase fails.
Future<SellCargo201ResponseData> purchaseCargo(
  Database db,
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
  await db.upsertShip(ship);
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Refuel [ship] at the current waypoint.
/// Returns the response data.
/// Throws an exception if the refuel fails.
Future<RefuelShip200ResponseData> refuelShip(
  Database db,
  Api api,
  AgentCache agentCache,
  Ship ship, {
  bool fromCargo = false,
}) async {
  // We used to have logic to avoid filling to full, but our route planner
  // doesn't account for non-full tanks, so for now we just always
  // refill to full.
  final request = fromCargo ? RefuelShipRequest(fromCargo: fromCargo) : null;
  final responseWrapper =
      await api.fleet.refuelShip(ship.symbol, refuelShipRequest: request);
  final data = responseWrapper!.data;
  await agentCache.updateAgent(Agent.fromOpenApi(data.agent));
  ship.fuel = data.fuel;
  await db.upsertShip(ship);
  return data;
}
