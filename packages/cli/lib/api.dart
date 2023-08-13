import 'package:cli/net/counts.dart';
import 'package:http/http.dart' as http;
import 'package:openapi/api.dart';

export 'package:openapi/api.dart';

/// The default http get function.
const defaultHttpGet = http.get;

/// The default implementation of getNow for production.
/// Used for tests for overriding the current time.
DateTime defaultGetNow() => DateTime.timestamp();

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

  /// The number of requests per second allowed by the api.
  int get maxRequestsPerSecond => 3;

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
