import 'package:cli/api.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/exceptions.dart';
import 'package:cli/net/queries.dart';
import 'package:cli/net/rate_limit.dart';
import 'package:file/file.dart';

/// The default path to the auth token.
const String defaultAuthTokenPath = 'data/auth_token.txt';

/// loadAuthToken loads the auth token from the given file system or
/// throws an error if it cannot be found.
String loadAuthToken(FileSystem fs, {String path = defaultAuthTokenPath}) {
  final token = fs.file(path).readAsStringSync().trim();
  if (token.isEmpty) {
    throw Exception('No auth token found.');
  }
  return token;
}

/// apiFromAuthToken creates an Api with the given auth token.
Api apiFromAuthToken(String token) {
  final auth = HttpBearerAuth()..accessToken = token;
  return Api(
    RateLimitedApiClient(authentication: auth),
  );
}

/// defaultApi creates an Api with the default auth token read from the
/// given file system.
Api defaultApi(FileSystem fs) {
  return apiFromAuthToken(loadAuthToken(fs));
}

/// loadAuthTokenOrRegister loads the auth token from the given file system
/// or registers a new user and returns the auth token.
Future<String> loadAuthTokenOrRegister(
  FileSystem fs, {
  String? callsign,
  String? email,
  String path = defaultAuthTokenPath,
}) async {
  try {
    return loadAuthToken(fs);
  } catch (e) {
    logger.info('No auth token found.');
    // Otherwise, register a new user.
    final handle = callsign ?? logger.prompt('What is your call sign?');
    final token = await register(callsign: handle, email: email);
    final file = fs.file(path);
    await file.create(recursive: true);
    await file.writeAsString(token);
    return token;
  }
}

Future<String> _tryRegister(
  DefaultApi api, {
  required String symbol,
  required FactionSymbols faction,
  String? email,
}) async {
  final registerRequest = RegisterRequest(
    symbol: symbol,
    faction: faction,
    email: email,
  );
  final registerResponse = await api.register(registerRequest: registerRequest);
  return registerResponse!.data.token;
}

/// register registers a new user with the space traders api and
/// returns the auth token which should be saved and used for future requests.
/// If the call sign is already taken, it will prompt for the email address
/// associated with the call sign.
Future<String> register({required String callsign, String? email}) async {
  final client = RateLimitedApiClient();
  final defaultApi = DefaultApi(client);

  final factions = await fetchAllPages(FactionsApi(client), (api, page) async {
    final response = await api.getFactions(page: page);
    return (response!.data, response.meta);
  }).toList();

  final recruitingFactions = factions.where((f) => f.isRecruiting).toList();

  // There are more factions in the game than players are allowed to join
  // at the start, so we use RegisterRequestFactionEnum.
  final faction = logger.chooseOne(
    'Choose a faction:',
    choices: recruitingFactions,
    display: (faction) {
      final f = factions.firstWhere((f) => f.symbol == faction.symbol);
      return '${f.symbol} - ${f.description}';
    },
  );

  try {
    return await _tryRegister(
      defaultApi,
      symbol: callsign,
      faction: faction.symbol,
      email: email,
    );
  } on ApiException catch (e) {
    if (!isReservedHandleException(e)) {
      logger.err('Exception registering: $e\n');
      rethrow;
    }
  }

  // This was a reserved handle. Ask for the email associated with it.
  try {
    final email = logger.prompt(
      'Call sign has been reserved between resets. Please enter the email '
      'associated with this call sign to proceed:',
    );
    return await _tryRegister(
      defaultApi,
      symbol: callsign,
      faction: faction.symbol,
      email: email,
    );
  } on ApiException catch (e) {
    logger.err('Exception registering: $e\n');
    rethrow;
  }
}
