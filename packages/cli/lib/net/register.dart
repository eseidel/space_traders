import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/auth.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

Future<String> _tryRegister(
  AccountsApi api, {
  required String symbol,
  required FactionSymbol faction,
}) async {
  final registerRequest = RegisterRequest(symbol: symbol, faction: faction);
  final registerResponse = await api.register(registerRequest);
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
  final accountsApi = AccountsApi(client);

  final factionsApi = FactionsApi(client);
  final factions = await fetchFactions(db, factionsApi);

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

  return await _tryRegister(
    accountsApi,
    symbol: agentSymbol,
    faction: chosenFaction.symbol,
  );
}
