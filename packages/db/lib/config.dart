import 'package:meta/meta.dart';

/// The default max age for our caches is 3 days.
/// This is used as a default argument and must be const.
const defaultMaxAge = Duration(days: 3);

/// Connection information for the database.
/// This is split off from Database to allow Database to re-connect
/// if needed.
@immutable
class DatabaseConfig {
  /// Create a new database config.
  const DatabaseConfig({
    required this.host,
    required this.port,
    required this.database,
    required this.username,
    required this.password,
  });

  /// Host of the database.
  final String host;

  /// Port of the database.
  final int port;

  /// Name of the database.
  final String database;

  /// Username to connect to the database.
  final String username;

  /// Password to connect to the database.
  final String password;
}

/// Default database config for connecting to a local postgres database.
const DatabaseConfig defaultDatabaseConfig = DatabaseConfig(
  host: 'localhost',
  port: 5432,
  database: 'spacetraders',
  username: 'postgres',
  password: 'password',
);
