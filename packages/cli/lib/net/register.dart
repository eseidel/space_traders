import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/exceptions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// loadAuthTokenOrRegister loads the auth token from the given file system
/// or registers a new user and returns the auth token.
Future<String> loadAuthTokenOrRegister(
  Database db, {
  String? agentName,
  String? email,
}) async {
  final token = await db.getAuthToken();
  if (token != null) {
    return token;
  } else {
    logger.info('No auth token found.');
    // Otherwise, register a new user.
    final name = agentName ?? logger.prompt('What is your agent name?');
    final token = await register(db, agentName: name, email: email);
    await db.setAuthToken(token);
    return token;
  }
}

Future<String> _tryRegister(
  DefaultApi api, {
  required String symbol,
  required FactionSymbol faction,
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
  Database db, {
  required String agentName,
  String? email,
  String? faction,
}) async {
  final client = getApiClient(db);
  final defaultApi = DefaultApi(client);

  final factionsApi = FactionsApi(client);
  final factions = await loadFactions(db, factionsApi);

  final recruitingFactions = factions.where((f) => f.isRecruiting).toList();

  // There are more factions in the game than players are allowed to join
  // at the start, so we use RegisterRequestFactionEnum.
  final Faction chosenFaction;
  if (faction != null) {
    chosenFaction =
        factions.firstWhere((f) => f.symbol.value == faction.toUpperCase());
  } else {
    logger.warn('Faction not specified. Choosing a random faction.');
    chosenFaction =
        recruitingFactions[Random().nextInt(recruitingFactions.length)];
  }

  try {
    return await _tryRegister(
      defaultApi,
      symbol: agentName,
      faction: chosenFaction.symbol,
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
      symbol: agentName,
      faction: chosenFaction.symbol,
      email: email,
    );
  } on ApiException catch (e) {
    logger.err('Exception registering: $e\n');
    rethrow;
  }
}
