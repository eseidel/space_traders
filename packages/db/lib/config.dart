import 'package:postgres/postgres.dart' as pg;

// TODO(eseidel): Move this up to cli/config.dart.
/// Default database config for connecting to a local postgres database.
pg.Endpoint defaultDatabaseEndpoint = pg.Endpoint(
  host: 'localhost',
  database: 'spacetraders',
  username: 'postgres',
  password: 'password',
);
