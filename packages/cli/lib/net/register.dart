import 'dart:math';

import 'package:cli/caches.dart';
import 'package:cli/net/auth.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// ChooseFaction is a function that chooses a faction from a list of factions.
typedef ChooseFaction = FactionSymbol Function(Iterable<Faction>);

/// randomFaction chooses a random faction from the given list of factions.
FactionSymbol randomFaction(Iterable<Faction> factions) {
  final recruitingFactions = factions.where((f) => f.isRecruiting).toList();
  if (recruitingFactions.isEmpty) {
    throw StateError('No recruiting factions found.');
  }
  return recruitingFactions[Random().nextInt(recruitingFactions.length)].symbol;
}

/// Registers a new user with the space traders api and returns the agent token
/// which should be saved and used for future requests.
/// By default will choose a random faction from the recruiting factions.
/// Pass a custom [chooseFaction] function to choose a faction other than the
/// default.
/// Registration can fail if the chosen faction is not recruiting, or if the
/// call sign is already taken.
Future<String> register(
  Database db, {
  required String agentSymbol,
  ChooseFaction chooseFaction = randomFaction,
}) async {
  final client = await getApiClient(db);

  // First figure out which faction to register as.
  final factions = await fetchFactions(db, FactionsApi(client));
  final factionSymbol = chooseFaction(factions.where((f) => f.isRecruiting));

  // Then try to register.
  final registerRequest = RegisterRequest(
    symbol: agentSymbol,
    faction: factionSymbol,
  );
  final registerResponse = await AccountsApi(client).register(registerRequest);
  return registerResponse.data.token;
}
