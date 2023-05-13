import 'package:space_traders_api/api.dart';

/// Api is a wrapper around the generated api clients.
/// It provides a single place to inject the api client.
/// This allows for easier mocking.
class Api {
  final ApiClient apiClient;
  final SystemsApi systems;
  final ContractsApi contracts;
  final AgentsApi agents;
  final FleetApi fleet;
  final FactionsApi factions;

  Api(this.apiClient)
      : systems = SystemsApi(apiClient),
        contracts = ContractsApi(apiClient),
        agents = AgentsApi(apiClient),
        fleet = FleetApi(apiClient),
        factions = FactionsApi(apiClient);
}

/// parseWaypointString parses a waypoint string into its component parts.
({String sector, String system, String waypoint}) parseWaypointString(
    String headquarters) {
  final parts = headquarters.split('-');
  return (
    sector: parts[0],
    system: "${parts[0]}-${parts[1]}",
    waypoint: "${parts[0]}-${parts[1]}-${parts[2]}",
  );
}

/// register registers a new user with the space traders api and
/// returns the auth token which should be saved and used for future requests.
Future<String> register(String callSign) async {
  final defaultApi = DefaultApi();

  final faction = RegisterRequestFactionEnum.values.first;

  RegisterRequest registerRequest = RegisterRequest(
    symbol: callSign,
    faction: faction,
  );
  Register201Response? registerResponse;
  try {
    registerResponse =
        await defaultApi.register(registerRequest: registerRequest);
    print(registerResponse);
  } catch (e) {
    print('Exception when calling DefaultApi->register: $e\n');
  }
  return registerResponse!.data.token;
}

/// findShipyard finds the shipyard in a system and returns the waypoint symbol.
Future<String?> findShipyard(Api api, String system) async {
  final waypointsResponse = await api.systems.getSystemWaypoints(system);
  for (var waypoint in waypointsResponse!.data) {
    if (waypoint.traits
        .any((t) => t.symbol == WaypointTraitSymbolEnum.SHIPYARD)) {
      return waypoint.symbol;
    }
  }
  return null;
}
