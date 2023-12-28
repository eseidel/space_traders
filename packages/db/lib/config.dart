import 'package:meta/meta.dart';

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

// TODO(eseidel): Move this up to cli/config.dart.
/// Default database config for connecting to a local postgres database.
const DatabaseConfig defaultDatabaseConfig = DatabaseConfig(
  host: 'localhost',
  port: 5432,
  database: 'spacetraders',
  username: 'postgres',
  password: 'password',
);
