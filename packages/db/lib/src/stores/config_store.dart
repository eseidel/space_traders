import 'package:db/db.dart';
import 'package:types/types.dart';

/// Store for configuration settings.
class ConfigStore {
  /// Create a new config store.
  ConfigStore(this._db);

  final Database _db;

  /// Get my agent symbol from the config table in the db.
  Future<String?> getAgentSymbol() async {
    final result = await _db.executeSql(
      "SELECT value FROM config_ WHERE key = 'agent_symbol'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  /// Set my agent symbol in the config table in the db.
  Future<void> setAgentSymbol(String symbol) async {
    await _db.executeSql(
      "INSERT INTO config_ (key, value) VALUES ('agent_symbol', "
      "'$symbol') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
    );
  }

  /// Get the game phase from the config table in the db.
  Future<GamePhase?> getGamePhase() async {
    final result = await _db.executeSql(
      "SELECT value FROM config_ WHERE key = 'game_phase'",
    );
    if (result.isEmpty) {
      return null;
    }
    return GamePhase.fromJson(result[0][0]! as String);
  }

  /// Set the game phase in the config table in the db.
  Future<void> setGamePhase(GamePhase phase) async {
    await _db.executeSql(
      "INSERT INTO config_ (key, value) VALUES ('game_phase', "
      "'${phase.toJson()}') "
      'ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
    );
  }

  /// Get the auth token from the config table in the db.
  Future<String?> getAuthToken() async {
    final result = await _db.executeSql(
      "SELECT value FROM config_ WHERE key = 'auth_token'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  /// Set the auth token in the config table in the db.
  Future<void> setAuthToken(String token) async {
    await _db.executeSql(
      "INSERT INTO config_ (key, value) VALUES ('auth_token', "
      "'$token') ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
    );
  }
}
