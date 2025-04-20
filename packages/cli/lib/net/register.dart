import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/net/exceptions.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

Future<String> _tryRegister(
  GlobalApi api, {
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
  required String agentSymbol,
  String? email,
  String? faction,
}) async {
  final client = getApiClient(db);
  final defaultApi = GlobalApi(client);

  final factionsApi = FactionsApi(client);
  final factions = await loadFactions(db, factionsApi);

  final recruitingFactions = factions.where((f) => f.isRecruiting).toList();

  // There are more factions in the game than players are allowed to join
  // at the start, so we use RegisterRequestFactionEnum.
  final Faction chosenFaction;
  if (faction != null) {
    chosenFaction = factions.firstWhere(
      (f) => f.symbol.value == faction.toUpperCase(),
    );
  } else {
    logger.warn('Faction not specified. Choosing a random faction.');
    chosenFaction =
        recruitingFactions[Random().nextInt(recruitingFactions.length)];
  }

  try {
    return await _tryRegister(
      defaultApi,
      symbol: agentSymbol,
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
      symbol: agentSymbol,
      faction: chosenFaction.symbol,
      email: email,
    );
  } on ApiException catch (e) {
    logger.err('Exception registering: $e\n');
    rethrow;
  }
}
