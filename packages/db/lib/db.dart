import 'package:db/construction.dart';
import 'package:db/extraction.dart';
import 'package:db/faction.dart';
import 'package:db/query.dart';
import 'package:db/survey.dart';
import 'package:db/transaction.dart';
import 'package:meta/meta.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Connection information for the database.
/// This is split off from Database to allow Database to re-connect
/// if needed.
class DatabaseConfig {
  /// Create a new database config.
  DatabaseConfig({
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

DatabaseConfig _defaultConfig() {
  return DatabaseConfig(
    host: 'localhost',
    port: 5432,
    database: 'spacetraders',
    username: 'postgres',
    password: 'password',
  );
}

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<Database> defaultDatabase({
  PostgreSQLConnection Function(DatabaseConfig config) createConnection =
      connectionFromConfig,
}) async {
  final db = Database(_defaultConfig(), createConnection: createConnection);
  await db.open();
  return db;
}

/// Create a connection from the given config.
PostgreSQLConnection connectionFromConfig(DatabaseConfig config) {
  return PostgreSQLConnection(
    config.host,
    config.port,
    config.database,
    username: config.username,
    password: config.password,
  );
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(
    this.config, {
    @visibleForTesting
    PostgreSQLConnection Function(DatabaseConfig config) createConnection =
        connectionFromConfig,
  }) : _connection = createConnection(config);

  /// The underlying connection.
  // TODO(eseidel): This shoudn't be public.
  // Make it private and move all callers into the db package.
  PostgreSQLConnection get connection => _connection;

  /// Not final so we can reset it.
  final PostgreSQLConnection _connection;

  /// Configure the database connection.
  final DatabaseConfig config;

  /// Open the database connection.
  Future<void> open() => connection.open();

  /// Close the database connection.
  Future<void> close() => connection.close();

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await connection.query('LISTEN $channel');
  }

  /// Insert one record using the provided query.
  @protected
  Future<void> insertOne(Query query) {
    return connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
  }

  /// Query for multiple records using the provided query.
  @protected
  Future<Iterable<T>> queryMany<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return connection
        .query(
          query.fmtString,
          substitutionValues: query.substitutionValues,
        )
        .then(
          (result) => result.map((r) => r.toColumnMap()).map(fromColumnMap),
        );
  }

  /// Query for a single record using the provided query.
  @protected
  Future<T?> queryOne<T>(
    Query query,
    T Function(Map<String, dynamic>) fromColumnMap,
  ) {
    return connection
        .query(
          query.fmtString,
          substitutionValues: query.substitutionValues,
        )
        .then(
          (result) =>
              result.isEmpty ? null : fromColumnMap(result.first.toColumnMap()),
        );
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(Transaction transaction) async {
    await insertOne(insertTransactionQuery(transaction));
  }

  /// Insert a survey into the database.
  Future<void> insertSurvey(HistoricalSurvey survey) async {
    await insertOne(insertSurveyQuery(survey));
  }

  /// Return the most recent surveys.
  Future<Iterable<HistoricalSurvey>> recentSurveysAtWaypoint(
    WaypointSymbol waypointSymbol, {
    required int count,
  }) async {
    final query = recentSurveysAtWaypointQuery(
      waypointSymbol: waypointSymbol,
      count: count,
    );
    return queryMany(query, surveyFromColumnMap);
  }

  /// Return all surveys.
  Future<Iterable<HistoricalSurvey>> allSurveys() async =>
      queryMany(allSurveysQuery(), surveyFromColumnMap);

  /// Mark the given survey as exhausted.
  Future<void> markSurveyExhausted(Survey survey) async {
    final query = markSurveyExhaustedQuery(survey);
    final result = await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
    if (result.affectedRowCount != 1) {
      throw ArgumentError('Survey not found: $survey');
    }
  }

  /// Gets all factions.
  Future<Iterable<Faction>> allFactions() =>
      queryMany(allFactionsQuery(), factionFromColumnMap);

  /// Cache the given factions.
  Future<void> cacheFactions(List<Faction> factions) async {
    await connection.transaction((connection) async {
      for (final faction in factions) {
        final query = insertFactionQuery(faction);
        await connection.query(
          query.fmtString,
          substitutionValues: query.substitutionValues,
        );
      }
    });
  }

  /// Return all extractions.
  Future<Iterable<ExtractionRecord>> allExtractions() async =>
      queryMany(allExtractionsQuery(), extractionFromColumnMap);

  /// Insert an extraction into the database.
  Future<void> insertExtraction(ExtractionRecord extraction) async =>
      insertOne(insertExtractionQuery(extraction));

  /// Return all construction records.
  Future<Iterable<ConstructionRecord>> allConstructionRecords() async =>
      queryMany(allConstructionQuery(), constructionFromColumnMap);
}
