import 'package:cli/net/counts.dart';
import 'package:http/http.dart' as http;
import 'package:types/types.dart';

/// The default http get function.
const defaultHttpGet = http.get;

/// Api is a wrapper around the generated api clients.
/// It provides a single place to inject the api client.
/// This allows for easier mocking.
class Api {
  /// Construct an Api with the given ApiClient.
  Api(this.apiClient)
    : systems = SystemsApi(apiClient),
      global = GlobalApi(apiClient),
      data = DataApi(apiClient),
      contracts = ContractsApi(apiClient),
      agents = AgentsApi(apiClient),
      fleet = FleetApi(apiClient),
      factions = FactionsApi(apiClient);

  /// The shared ApiClient.
  final CountingApiClient apiClient;

  /// Counts of requests sent through this api.
  RequestCounts get requestCounts => apiClient.requestCounts;

  /// GlobalApi generated client.
  final GlobalApi global;

  /// Backwards compatibility for the defaultApi getter.
  GlobalApi get defaultApi => global;

  /// DataApi generated client.
  final DataApi data;

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
