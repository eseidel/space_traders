import 'package:cli/api.dart';
import 'package:types/types.dart';

/// The default page size for API requests.
// The default size in the OpenAPI spec is 10, but the max is 20.
const int pageLimit = 20;

/// Fetches all pages from the given fetchPage function.
Stream<T> fetchAllPages<T, A>(
  A api,
  Future<(List<T>, Meta)> Function(A api, int page) fetchPage,
) async* {
  var page = 1;
  var count = 0;
  var remaining = 0;
  do {
    final (values, meta) = await fetchPage(api, page);
    count += values.length;
    remaining = meta.total - count;
    for (final value in values) {
      yield value;
    }
    page++;
  } while (remaining > 0);
}

/// Fetches a single waypoint.
Future<Waypoint> fetchWaypoint(Api api, WaypointSymbol waypointSymbol) async {
  final response = await api.systems.getWaypoint(
    waypointSymbol.systemString,
    waypointSymbol.toJson(),
  );
  final openApiWaypoint = response!.data;
  return Waypoint.fromOpenApi(openApiWaypoint);
}

/// Fetches all waypoints in a system.  Handles pagination from the server.
Stream<Waypoint> allWaypointsInSystem(Api api, SystemSymbol system) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.systems
        .getSystemWaypoints(system.system, page: page, limit: pageLimit);
    final waypoints = response!.data.map(Waypoint.fromOpenApi).toList();
    return (waypoints, response.meta);
  });
}

/// Fetches all of the user's ships.  Handles pagination from the server.
Stream<Ship> allMyShips(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.fleet.getMyShips(page: page, limit: pageLimit);
    final ships = response!.data.map(Ship.fromOpenApi).toList();
    return (ships, response.meta);
  });
}

/// Fetches all of the user's contracts.  Handles pagination from the server.
Stream<Contract> allMyContracts(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response =
        await api.contracts.getContracts(page: page, limit: pageLimit);
    final now = DateTime.timestamp();
    final contracts =
        response!.data.map((c) => Contract.fromOpenApi(c, now)).toList();
    return (contracts, response.meta);
  });
}

/// Fetches all factions.  Handles pagination from the server.
Stream<Faction> getAllFactions(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response =
        await api.factions.getFactions(page: page, limit: pageLimit);
    return (response!.data, response.meta);
  });
}

/// Fetch user's [Agent] object.
Future<Agent> getMyAgent(Api api) async {
  final response = await api.agents.getMyAgent();
  return Agent.fromOpenApi(response!.data);
}

/// Fetch shipyard for a given waypoint, will throw if the waypoint does not
/// have a shipyard.
Future<Shipyard> getShipyard(Api api, WaypointSymbol waypointSymbol) async {
  final response = await api.systems.getShipyard(
    waypointSymbol.systemString,
    waypointSymbol.waypoint,
  );
  return response!.data;
}

/// Returns JumpGate object for passed in Waypoint.
Future<JumpGate> getJumpGate(Api api, WaypointSymbol waypointSymbol) async {
  final response = await api.systems
      .getJumpGate(waypointSymbol.systemString, waypointSymbol.waypoint);
  return JumpGate.fromOpenApi(response!.data);
}

/// Fetches Market for a given Waypoint.
Future<Market> getMarket(Api api, WaypointSymbol waypointSymbol) async {
  final response = await api.systems
      .getMarket(waypointSymbol.systemString, waypointSymbol.waypoint);
  return response!.data;
}

/// Fetches Scrap value for a given Ship.
/// Ship must be docked at a shipyard.
Future<ScrapTransaction?> getScrapValue(Api api, ShipSymbol symbol) async {
  final response = await api.fleet.getScrapShip(symbol.symbol);
  return response?.data.transaction;
}

/// Fetches Construction for a given Waypoint.
Future<Construction> getConstruction(
  Api api,
  WaypointSymbol waypointSymbol,
) async {
  final response = await api.systems.getConstruction(
    waypointSymbol.systemString,
    waypointSymbol.waypoint,
  );
  return response!.data;
}
