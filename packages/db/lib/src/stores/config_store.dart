import 'package:db/db.dart';
import 'package:types/types.dart';

/// Store for configuration settings.
class ConfigStore {
  /// Create a new config store.
  ConfigStore(this._db);

  final Database _db;

  Future<String?> _getString(String key) async {
    final result = await _db.executeSql(
      "SELECT value FROM config_ WHERE key = '$key'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  Future<void> _setString(String key, String value) async {
    await _db.executeSql(
      "INSERT INTO config_ (key, value) VALUES ('$key', '$value') "
      'ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
    );
  }

  /// Get my agent symbol from the config table in the db.
  Future<String?> getAgentSymbol() async => _getString('agent_symbol');

  /// Set my agent symbol in the config table in the db.
  Future<void> setAgentSymbol(String symbol) async {
    await _setString('agent_symbol', symbol);
  }

  /// Get the game phase from the config table in the db.
  Future<GamePhase?> getGamePhase() async {
    final result = await _getString('game_phase');
    if (result == null) {
      return null;
    }
    return GamePhase.fromJson(result);
  }

  /// Set the game phase in the config table in the db.
  Future<void> setGamePhase(GamePhase phase) async {
    await _setString('game_phase', phase.toJson());
  }

  /// Get the agent token from the config table in the db.
  /// Agent tokens short-lived, only per-reset (e.g. weekly).
  Future<String?> getAgentToken() async => _getString('agent_token');

  /// Set the agent token in the config table in the db.
  Future<void> setAgentToken(String token) async {
    await _setString('agent_token', token);
  }

  /// Get the account token from the config table in the db.
  /// Account token is long-lived and allows creation of new agents.
  Future<String?> getAccountToken() async => _getString('account_token');

  /// Set the account token in the config table in the db.
  Future<void> setAccountToken(String token) async {
    await _setString('account_token', token);
  }
}
