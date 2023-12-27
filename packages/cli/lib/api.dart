import 'package:cli/net/counts.dart';
import 'package:http/http.dart' as http;
import 'package:openapi/api.dart'
    show AgentsApi, ContractsApi, DefaultApi, FactionsApi, FleetApi, SystemsApi;

/// The default http get function.
const defaultHttpGet = http.get;

/// Api is a wrapper around the generated api clients.
/// It provides a single place to inject the api client.
/// This allows for easier mocking.
class Api {
  /// Construct an Api with the given ApiClient.
  Api(this.apiClient)
      : systems = SystemsApi(apiClient),
        defaultApi = DefaultApi(apiClient),
        contracts = ContractsApi(apiClient),
        agents = AgentsApi(apiClient),
        fleet = FleetApi(apiClient),
        factions = FactionsApi(apiClient);

  /// The shared ApiClient.
  final CountingApiClient apiClient;

  /// Counts of requests sent through this api.
  RequestCounts get requestCounts => apiClient.requestCounts;

  /// DefaultApi generated client.
  final DefaultApi defaultApi;

  /// SystemApi generated client.
  final SystemsApi systems;

  /// ContractsApi generated client.
  final ContractsApi contracts;

  /// AgentsApi generated client.
  final AgentsApi agents;

  /// FleetApi generated client.
  final FleetApi fleet;

  /// FactionsApi generated client.
  final FactionsApi factions;
}
