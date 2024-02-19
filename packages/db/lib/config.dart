import 'package:postgres/postgres.dart' as pg;

// TODO(eseidel): Move this up to cli/config.dart.
/// Default database config for connecting to a local postgres database.
pg.Endpoint defaultDatabaseEndpoint = pg.Endpoint(
  host: 'localhost',
  database: 'spacetraders',
  username: 'postgres',
  password: 'password',
);

/// Currently we use a docker container by default, which does not have its
/// own ssl cert so we're disabling ssl for now.
pg.ConnectionSettings defaultDatabaseConnectionSettings =
    const pg.ConnectionSettings(
  sslMode: pg.SslMode.disable,
);
