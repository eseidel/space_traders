import 'package:db/config.dart';
import 'package:db/migrations.dart';
import 'package:db/src/queries.dart';
import 'package:db/src/query.dart';
import 'package:db/src/stores.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:types/types.dart';

export 'package:db/config.dart';
export 'package:db/src/stores.dart';

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<Database> defaultDatabase({
  @visibleForTesting
  Future<pg.Connection> Function(pg.Endpoint endpoint, pg.ConnectionSettings?)
      openConnection =
      _defaultOpenConnection,
}) async {
  final db = Database(
    defaultDatabaseEndpoint,
    settings: defaultDatabaseConnectionSettings,
  );
  await db.open(openConnection: openConnection);
  await db.migrateToLatestSchema();
  return db;
}

Future<pg.Connection> _defaultOpenConnection(
  pg.Endpoint endpoint,
  pg.ConnectionSettings? settings,
) {
  return pg.Connection.open(endpoint, settings: settings);
}

/// Wrapper around a database connection.
class DatabaseConnection {
  /// Create a new database connection.
  DatabaseConnection(this._connection);

  /// The underlying connection, private to this class.  Methods on this class
  /// should use execute().
  final pg.Connection _connection;

  /// The number of queries made.
  final QueryCounts queryCounts = QueryCounts();

  /// Close the database connection.
  Future<void> close() => _connection.close();

  /// Wait for a notification on a channel.
  Future<void> waitOnChannel(String channel) async {
    await _connection.channels[channel].first;
  }

  /// Execute a query on a session.
  static Future<pg.Result> executeOnSession(pg.Session session, Query query) {
    return session.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
  }

  /// Execute a query.
  Future<pg.Result> execute(Query query) {
    queryCounts.record(query.fmtString);
    return _connection.execute(
      pg.Sql.named(query.fmtString),
      parameters: query.parameters,
    );
  }

  /// Execute a query.
  Future<pg.Result> executeSql(String sql) {
    queryCounts.record(sql);
    return _connection.execute(sql);
  }

  /// Run a transaction.
  Future<R> runTx<R>(Future<R> Function(pg.TxSession session) fn) async {
    return _connection.runTx(fn);
  }
}

/// {@template database_error}
/// An exception that is thrown when an error occurs while
/// interacting with the database.
/// {@endtemplate}
class DatabaseError implements Exception {
  /// {@macro database_error}
  const DatabaseError({required this.message});

  /// The error message.
  final String message;

  @override
  String toString() => message;
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.endpoint, {this.settings});

  /// Create a new database with mock connection for testing.
  @visibleForTesting
  Database.test(this._connection)
    : endpoint = pg.Endpoint(host: 'localhost', database: 'test'),
      settings = null;

  /// Create a new database with a live connection for testing.
  /// This probably could be removed and override openConnection instead.
  @visibleForTesting
  Database.testLive({
    required this.endpoint,
    required pg.Connection connection,
    this.settings,
  }) {
    _connection = DatabaseConnection(connection);
  }

  /// Configure the database connection.
  final pg.Endpoint endpoint;

  /// Configure the database connection.
  final pg.ConnectionSettings? settings;

  late final DatabaseConnection _connection;

  /// The number of queries made.
  QueryCounts get queryCounts => _connection.queryCounts;

  /// Open the database connection.
  Future<void> open({
    @visibleForTesting
    Future<pg.Connection> Function(
          pg.Endpoint endpoint,
          pg.ConnectionSettings? settings,
        )
        openConnection =
        _defaultOpenConnection,
  }) async {
    _connection = DatabaseConnection(await openConnection(endpoint, settings));
  }

  /// Close the database connection.
  Future<void> close() => _connection.close();

  /// Migrate the database to the latest schema version.
  Future<void> migrateToLatestSchema() {
    return migrateToSchema(version: allMigrations.last.version);
  }

  /// Get the current schema version.
  Future<int?> currentSchemaVersion() async {
    try {
      final result = await execute(selectCurrentSchemaVersionQuery());
      if (result.isEmpty) {
        return null;
      }
      return result.first[0] as int?;
    } on pg.ServerException catch (e) {
      // The table may not exist yet.
      if (e.code == '42P01') {
        return null;
      }
      rethrow;
    }
  }

  /// Migrate the database to the given schema version.
  Future<void> migrateToSchema({required int version}) async {
    // Ensure the schema version table exists. This query is idempotent and
    // does not need to be run as part of the transaction.
    await execute(createSchemaVersionTableQuery());

    final maybeSchemaVersion = await currentSchemaVersion();

    // If the target version is the same as the current version, do nothing.
    // If the target version is higher, migrate up.
    // If the target version is lower, migrate down.
    if (maybeSchemaVersion == version) return;

    return _connection.runTx((session) async {
      final schemaVersion = maybeSchemaVersion ?? 0;

      final scripts = migrationScripts(
        fromVersion: schemaVersion,
        toVersion: version,
      );

      for (final script in scripts) {
        try {
          await session.execute(script);
        } catch (e) {
          await session.rollback();
          throw DatabaseError(
            message: 'Failed to run migration script: $script due to $e',
          );
        }
      }

      final updateVersionQuery = upsertSchemaVersionQuery(version);
      try {
        await DatabaseConnection.executeOnSession(session, updateVersionQuery);
      } on Exception catch (e) {
        await session.rollback();
        throw DatabaseError(
          message: 'Failed to update schema version to $version: $e',
        );
      }
    });
  }

  /// Get the behavior store.
  BehaviorStore get behaviors => BehaviorStore(this);

  /// Get the config store.
  ConfigStore get config => ConfigStore(this);

  /// Get the construction store.
  ConstructionStore get construction => ConstructionStore(this);

  /// Get the contract store.
  ContractStore get contracts => ContractStore(this);

  /// Get the charting store.
  ChartingStore get charting => ChartingStore(this);

  /// Get the extraction store.
  ExtractionStore get extractions => ExtractionStore(this);

  /// Get the jump gate store.
  JumpGateStore get jumpGates => JumpGateStore(this);

  /// Get the transaction store.
  TransactionStore get transactions => TransactionStore(this);

  /// Get the market listing store.
  MarketListingStore get marketListings => MarketListingStore(this);

  /// Get the market price store.
  MarketPriceStore get marketPrices => MarketPriceStore(this);

  /// Get the shipyard price store.
  ShipyardPriceStore get shipyardPrices => ShipyardPriceStore(this);

  /// Get the shipyard listing store.
  ShipyardListingStore get shipyardListings => ShipyardListingStore(this);

  /// Get the survey store.
  SurveyStore get surveys => SurveyStore(this);

  /// Get the systems store.
  SystemsStore get systems => SystemsStore(this);

  /// Get the ship mount store.
  ShipMountStore get shipMounts => ShipMountStore(this);

  /// Get the ship module store.
  ShipModuleStore get shipModules => ShipModuleStore(this);

  /// Get the shipyard ship store.
  ShipyardShipStore get shipyardShips => ShipyardShipStore(this);

  /// Get the ship engine store.
  ShipEngineStore get shipEngines => ShipEngineStore(this);

  /// Get the reactor store.
  ShipReactorStore get shipReactors => ShipReactorStore(this);

  /// Get the waypoint trait store.
  WaypointTraitStore get waypointTraits => WaypointTraitStore(this);

  /// Get the trade good store.
  TradeGoodStore get tradeGoods => TradeGoodStore(this);

  /// Get the trade export store.
  TradeExportStore get tradeExports => TradeExportStore(this);

  /// Event store.
  EventStore get events => EventStore(this);

  /// Get the network store.
  NetworkStore get network => NetworkStore(this);

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await executeSql('LISTEN $channel');
  }

  /// Notify listeners on a channel.
  Future<void> notify(String channel, [Object? payload]) async {
    if (payload == null) {
      await executeSql('NOTIFY $channel');
    } else {
      await executeSql("NOTIFY $channel, '$payload'");
    }
  }

  /// Wait for a notification on a channel.
  Future<void> waitOnChannel(String channel) async {
    await _connection.waitOnChannel(channel);
  }

  /// Execute a query.
  Future<pg.Result> execute(Query query) => _connection.execute(query);

  /// Execute a query.
  Future<pg.Result> executeSql(String sql) => _connection.executeSql(sql);

  /// Query for multiple records using the provided query.
  Future<Iterable<T>> queryMany<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return execute(
      query,
    ).then((result) => result.map((r) => r.toColumnMap()).map(fromColumnMap));
  }

  /// Query for a single record using the provided query.
  Future<T?> queryOne<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return execute(query).then(
      (result) =>
          result.isEmpty ? null : fromColumnMap(result.first.toColumnMap()),
    );
  }

  /// Return a list of all table names.
  Future<Iterable<String>> allTableNames() async {
    final result = await executeSql(
      'SELECT table_name FROM information_schema.tables '
      "WHERE table_schema = 'public' "
      'ORDER BY table_name',
    );
    return result.map((r) => r.first! as String);
  }

  /// Return the number of rows in the given table.
  Future<int> rowsInTable(String tableName) async {
    final result = await executeSql('SELECT COUNT(*) FROM $tableName');
    return result[0][0]! as int;
  }

  /// Gets all factions.
  Future<Iterable<Faction>> allFactions() =>
      queryMany(allFactionsQuery(), factionFromColumnMap);

  /// Cache the given factions.
  Future<void> upsertFaction(Faction faction) async {
    await execute(upsertFactionQuery(faction));
  }

  /// Get my agent from the db.
  Future<Agent?> getMyAgent() async {
    final symbol = await config.getAgentSymbol();
    if (symbol == null) {
      return null;
    }
    return getAgent(symbol: symbol);
  }

  /// Get the agent from the database.
  Future<Agent?> getAgent({required String symbol}) async {
    final query = agentBySymbolQuery(symbol);
    return queryOne(query, agentFromColumnMap);
  }

  /// Update the given agent in the database.
  Future<void> upsertAgent(Agent agent) async {
    await execute(upsertAgentQuery(agent));
  }

  /// Get all ships.
  Future<Iterable<Ship>> allShips() async {
    return queryMany(allShipsQuery(), shipFromColumnMap);
  }

  /// Get a ship by symbol.
  Future<Ship?> getShip(ShipSymbol symbol) async {
    final query = shipBySymbolQuery(symbol);
    return queryOne(query, shipFromColumnMap);
  }

  /// Upsert a ship into the database.
  Future<void> upsertShip(Ship ship) async {
    await execute(upsertShipQuery(ship));
  }

  /// Delete a ship from the database.
  Future<void> deleteShip(ShipSymbol symbol) async {
    await execute(deleteShipQuery(symbol));
  }

  /// Get static data of type [type] and key [key] from the static_data_ table.
  /// Returns null if not found.
  Future<Map<String, dynamic>?> getFromStaticCache({
    required Type type,
    required String key,
  }) async {
    final result = await queryOne(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type AND key = @key',
        parameters: {'type': type.toString(), 'key': key},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  /// Get all static data of type [type] from the static_data_ table.
  /// Returns an empty list if not found.
  Future<Iterable<Map<String, dynamic>>> getAllFromStaticCache({
    required Type type,
  }) async {
    final result = await queryMany(
      Query(
        'SELECT json FROM static_data_ WHERE type = @type',
        parameters: {'type': type.toString()},
      ),
      (map) => map['json'] as Map<String, dynamic>,
    );
    return result;
  }

  /// Upsert static data of type [type] and key [key] into the
  /// static_data_ table.
  /// If the data already exists, it will be updated.
  Future<void> upsertInStaticCache({
    required Type type,
    required String key,
    required Map<String, dynamic> json,
    // Reset is intended to store which reset the data was created in.
    // But we've not wired it up yet.
    String reset = '1',
  }) async {
    await execute(
      Query(
        'INSERT INTO static_data_ (type, key, reset, json) '
        'VALUES (@type, @key, @reset, @json) '
        'ON CONFLICT (type, key) DO UPDATE SET json = EXCLUDED.json',
        parameters: {
          'type': type.toString(),
          'key': key,
          'json': json,
          'reset': reset,
        },
      ),
    );
  }
}
