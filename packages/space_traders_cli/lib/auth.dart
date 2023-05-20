import 'package:file/file.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/rate_limit.dart';

/// Api is a wrapper around the generated api clients.
/// It provides a single place to inject the api client.
/// This allows for easier mocking.
class Api {
  /// Construct an Api with the given ApiClient.
  Api(this.apiClient)
      : systems = SystemsApi(apiClient),
        contracts = ContractsApi(apiClient),
        agents = AgentsApi(apiClient),
        fleet = FleetApi(apiClient),
        factions = FactionsApi(apiClient);

  /// The shared ApiClient.
  final ApiClient apiClient;

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

/// loadAuthToken loads the auth token from the given file system or
/// throws an error if it cannot be found.
String loadAuthToken(FileSystem fs) {
  final token = fs.file('auth_token.txt').readAsStringSync().trim();
  if (token.isEmpty) {
    throw Exception('No auth token found.');
  }
  return token;
}

/// apiFromAuthToken creates an Api with the given auth token.
Api apiFromAuthToken(String token) {
  final auth = HttpBearerAuth()..accessToken = token;
  return Api(RateLimitedApiClient(requestsPerSecond: 2, authentication: auth));
}

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Api defaultApi(FileSystem fs) {
  return apiFromAuthToken(loadAuthToken(fs));
}

/// loadAuthTokenOrRegister loads the auth token from the given file system
/// or registers a new user and returns the auth token.
Future<String> loadAuthTokenOrRegister(FileSystem fs) async {
  try {
    return loadAuthToken(fs);
  } catch (e) {
    logger.info('No auth token found.');
    // Otherwise, register a new user.
    final handle = logger.prompt('What is your call sign?');
    final token = await register(handle);
    await fs.file('auth_token.txt').writeAsString(token);
    return token;
  }
}

/// register registers a new user with the space traders api and
/// returns the auth token which should be saved and used for future requests.
Future<String> register(String callSign) async {
  final defaultApi = DefaultApi();

  final factions = await fetchAllPages(FactionsApi(), (api, page) async {
    final response = await api.getFactions(page: page);
    return (response!.data, response.meta);
  }).toList();

  // There are more factions in the game than players are allowed to join
  // at the start, so we use RegisterRequestFactionEnum.
  final faction = logger.chooseOne(
    'Choose a faction:',
    choices: RegisterRequestFactionEnum.values,
    display: (faction) {
      final f = factions.firstWhere((f) => f.symbol == faction.value);
      return '${f.symbol} - ${f.description}';
    },
  );

  final registerRequest = RegisterRequest(
    symbol: callSign,
    faction: faction,
  );
  Register201Response? registerResponse;
  try {
    registerResponse =
        await defaultApi.register(registerRequest: registerRequest);
    // print(registerResponse);
  } catch (e) {
    logger.err('Exception when calling DefaultApi->register: $e\n');
  }
  return registerResponse!.data.token;
}
