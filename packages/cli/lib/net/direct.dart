import 'package:cli/api.dart';
import 'package:cli/cache/static_cache.dart';
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
  WaypointSymbol shipyardSymbol,
  ShipType shipType,
) async {
  final purchaseResponse = await api.fleet.purchaseShip(
    PurchaseShipRequest(
      waypointSymbol: shipyardSymbol.waypoint,
      shipType: shipType,
    ),
  );
  final data = purchaseResponse!.data;
  // Add the new ship to our cache.
  await db.upsertShip(Ship.fromOpenApi(data.ship));
  await db.upsertAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Scrap the ship with [shipSymbol]
/// Must be docked at a shipyard.
Future<ScrapShip200ResponseData> scrapShip(
  Database db,
  Api api,
  ShipSymbol shipSymbol,
) async {
  final scrapResponse = await api.fleet.scrapShip(shipSymbol.symbol);
  final data = scrapResponse!.data;
  // Remove the ship from our cache.
  await db.deleteShip(shipSymbol);
  await db.upsertAgent(Agent.fromOpenApi(data.agent));
  // Caller records the transaction.
  return data;
}

/// Set the [flightMode] of [ship]
Future<void> setShipFlightMode(
  Database db,
  Api api,
  Ship ship,
  ShipNavFlightMode flightMode,
) async {
  final request = PatchShipNavRequest(flightMode: flightMode);
  final response = await api.fleet.patchShipNav(
    ship.symbol.symbol,
    patchShipNavRequest: request,
  );
  final data = response!.data;
  ship
    ..nav = data.nav
    ..fuel = data.fuel;
  recordEvents(db, ship, data.events);
  await db.upsertShip(ship);
}

/// Navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> navigateShip(
  Database db,
  Api api,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypointSymbol.waypoint);
  final result = await api.fleet.navigateShip(ship.symbol.symbol, request);
  final data = result!.data;
  ship
    ..nav = data.nav
    ..fuel = data.fuel;
  await db.upsertShip(ship);
  return data;
}

/// Navigate [ship] to [waypointSymbol]
Future<NavigateShip200ResponseData> warpShip(
  Database db,
  Api api,
  Ship ship,
  WaypointSymbol waypointSymbol,
) async {
  final request = NavigateShipRequest(waypointSymbol: waypointSymbol.waypoint);
  final result = await api.fleet.warpShip(ship.symbol.symbol, request);
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
  final response = await api.fleet.siphonResources(ship.symbol.symbol);
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
  final response = await api.fleet.extractResources(ship.symbol.symbol);
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
  final response = await api.fleet.extractResourcesWithSurvey(
    ship.symbol.symbol,
    survey: survey,
  );
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
    shipSymbol: ship.symbol.symbol,
    tradeSymbol: tradeSymbol.value,
    units: units,
  );
  final response = await api.contracts.deliverContract(contract.id, request);
  final data = response!.data;
  await db.contracts.upsert(
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
  Construction construction, {
  required TradeSymbol tradeSymbol,
  required int units,
}) async {
  final request = SupplyConstructionRequest(
    shipSymbol: ship.symbol.symbol,
    tradeSymbol: tradeSymbol,
    units: units,
  );
  final response = await api.systems.supplyConstruction(
    construction.waypointSymbol.systemString,
    construction.waypointSymbol.waypoint,
    request,
  );
  final data = response!.data;
  await db.construction.updateConstruction(
    construction.waypointSymbol,
    data.construction,
  );
  ship.cargo = data.cargo;
  await db.upsertShip(ship);
  return data;
}

/// Sell [units] of [tradeSymbol] to market.
Future<PurchaseCargo201ResponseData> sellCargo(
  Database db,
  Api api,
  Ship ship,
  TradeSymbol tradeSymbol,
  int units,
) async {
  final request = SellCargoRequest(symbol: tradeSymbol, units: units);
  final response = await api.fleet.sellCargo(ship.symbol.symbol, request);
  final data = response!.data;
  ship.cargo = data.cargo;
  await db.upsertShip(ship);
  await db.upsertAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Purchase [units] of [tradeSymbol] from market.
/// Returns the response data.
/// Throws an exception if the purchase fails.
Future<PurchaseCargo201ResponseData> purchaseCargo(
  Database db,
  Api api,
  Ship ship,
  TradeSymbol tradeSymbol,
  int units,
) async {
  final request = PurchaseCargoRequest(symbol: tradeSymbol, units: units);
  final response = await api.fleet.purchaseCargo(ship.symbol.symbol, request);
  final data = response!.data;
  ship.cargo = data.cargo;
  await db.upsertShip(ship);
  await db.upsertAgent(Agent.fromOpenApi(data.agent));
  return data;
}

/// Refuel [ship] at the current waypoint.
/// Returns the response data.
/// Throws an exception if the refuel fails.
Future<RefuelShip200ResponseData> refuelShip(
  Database db,
  Api api,
  Ship ship, {
  bool fromCargo = false,
}) async {
  // We used to have logic to avoid filling to full, but our route planner
  // doesn't account for non-full tanks, so for now we just always
  // refill to full.
  // Always send an explicit request to avoid the server being confused
  // about an empty body with application/json as content type.
  // Remove this once the server is fixed.
  // https://discord.com/channels/792864705139048469/1371193425348526100
  final fullRefuel = RefuelShipRequest(
    units: ship.fuel.capacity - ship.fuel.current,
  );
  final request =
      fromCargo ? RefuelShipRequest(fromCargo: fromCargo) : fullRefuel;
  final responseWrapper = await api.fleet.refuelShip(
    ship.symbol.symbol,
    refuelShipRequest: request,
  );
  final data = responseWrapper!.data;
  await db.upsertAgent(Agent.fromOpenApi(data.agent));
  ship.fuel = data.fuel;
  if (data.cargo != null) {
    ship.cargo = data.cargo!;
  }
  await db.upsertShip(ship);
  return data;
}
