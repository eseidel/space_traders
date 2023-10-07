import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/exceptions.dart';
import 'package:db/db.dart';
import 'package:types/api.dart';

/// loadAuthTokenOrRegister loads the auth token from the given file system
/// or registers a new user and returns the auth token.
Future<String> loadAuthTokenOrRegister(
  FileSystem fs,
  Database db, {
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
    final token = await register(fs, db, callsign: handle, email: email);
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
Future<String> register(
  FileSystem fs,
  Database db, {
  required String callsign,
  String? email,
}) async {
  final systemsCache = await SystemsCache.load(fs);
  final clusterCache = SystemConnectivity.fromSystemsCache(systemsCache);

  final client = getApiClient(db, getPriority: () => 0);
  final defaultApi = DefaultApi(client);

  final factionsApi = FactionsApi(client);
  final factions = await loadFactions(db, factionsApi);

  final recruitingFactions = factions.where((f) => f.isRecruiting).toList();

  // There are more factions in the game than players are allowed to join
  // at the start, so we use RegisterRequestFactionEnum.
  final faction = logger.chooseOne(
    'Choose a faction:',
    choices: recruitingFactions,
    display: (faction) {
      final f = factions.firstWhere((f) => f.symbol == faction.symbol);
      final reachable =
          clusterCache.connectedSystemCount(f.headquartersSymbol.systemSymbol);
      return '${f.symbol} - connected to $reachable systems';
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
