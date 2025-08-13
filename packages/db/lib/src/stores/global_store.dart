import 'package:db/db.dart';

/// Store for global settings.
class GlobalStore {
  /// Create a new global store.
  GlobalStore(this._db);

  final Database _db;

  Future<String?> _getString(String key) async {
    final result = await _db.executeSql(
      "SELECT value FROM global_ WHERE key = '$key'",
    );
    if (result.isEmpty) {
      return null;
    }
    return result[0][0]! as String;
  }

  Future<void> _setString(String key, String value) async {
    await _db.executeSql(
      "INSERT INTO global_ (key, value) VALUES ('$key', '$value') "
      'ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value',
    );
  }

  /// Get the account token from the global table in the db.
  /// Account token is long-lived and allows creation of new agents.
  Future<String?> getAccountToken() async => _getString('account_token');

  /// Set the account token in the global table in the db.
  Future<void> setAccountToken(String token) async {
    await _setString('account_token', token);
  }

  /// Get the base url from the config table in the db.
  Future<Uri?> getBaseUrl() async {
    final maybeString = await _getString('base_url');
    if (maybeString == null) {
      return null;
    }
    return Uri.parse(maybeString);
  }

  /// Set the base url in the config table in the db.
  Future<void> setBaseUrl(Uri url) async {
    await _setString('base_url', url.toString());
  }
}
