import 'package:db/extraction.dart';
import 'package:db/faction.dart';
import 'package:db/survey.dart';
import 'package:db/transaction.dart';
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
Future<Database> defaultDatabase() async {
  final db = Database(_defaultConfig());
  await db.open();
  return db;
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.config) : _connection = connectionFromConfig(config);

  /// Create a connection from the given config.
  static PostgreSQLConnection connectionFromConfig(DatabaseConfig config) {
    return PostgreSQLConnection(
      config.host,
      config.port,
      config.database,
      username: config.username,
      password: config.password,
    );
  }

  /// Insert a transaction into the database.
  Future<void> insertTransaction(Transaction transaction) async {
    final query = insertTransactionQuery(transaction);
    await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
  }

  /// The underlying connection.
  // TODO(eseidel): This shoudn't be public.
  // Make it private and move all callers into the db package.
  PostgreSQLConnection get connection => _connection;

  /// Not final so we can reset it.
  PostgreSQLConnection _connection;

  /// When the connection was opened.
  DateTime? _connectionOpenTime;

  /// Configure the database connection.
  final DatabaseConfig config;

  /// Open the database connection.
  Future<void> open() {
    _connectionOpenTime = DateTime.timestamp();
    return connection.open();
  }

  /// Close the database connection.
  Future<void> close() => connection.close();

  /// Reset the database connection.
  // This is a hack around the fact that our long connections to postgres
  // seem to cause a leak on the server side?
  Future<void> reconnect() async {
    if (!connection.isClosed) {
      await close();
    }
    _connection = connectionFromConfig(config);
    return open();
  }

  /// Reconnect if the connection has been open for more than an hour.
  /// This is a hack around a unknown leak we're triggering in postgres.
  Future<void> reconnectIfNeeded() async {
    final openTime = _connectionOpenTime;
    if (openTime == null) {
      return;
    }
    if (DateTime.timestamp().difference(openTime) < const Duration(hours: 1)) {
      return;
    }
    await reconnect();
  }

  /// Listen for notifications on a channel.
  Future<void> listen(String channel) async {
    await connection.query('LISTEN $channel');
  }

  /// Insert a survey into the database.
  Future<void> insertSurvey(HistoricalSurvey survey) async {
    final query = insertSurveyQuery(survey);
    await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
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
    final result = await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
    return result
        .map((r) => r.toColumnMap())
        .map<HistoricalSurvey>(surveyFromColumnMap);
  }

  /// Return all surveys.
  Future<Iterable<HistoricalSurvey>> allSurveys() async {
    final query = allSurveysQuery();
    final result = await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
    return result
        .map((r) => r.toColumnMap())
        .map<HistoricalSurvey>(surveyFromColumnMap);
  }

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

  /// Gets the faction with the given symbol.
  Future<Faction> factionBySymbol(FactionSymbols symbol) {
    final query = factionBySymbolQuery(symbol);
    return connection
        .query(query.fmtString, substitutionValues: query.substitutionValues)
        .then((result) => factionFromColumnMap(result.first.toColumnMap()));
  }

  /// Gets all factions.
  Future<List<Faction>> allFactions() {
    final query = allFactionsQuery();
    return connection
        .query(query.fmtString, substitutionValues: query.substitutionValues)
        .then(
          (result) => result
              .map((r) => r.toColumnMap())
              .map(factionFromColumnMap)
              .toList(),
        );
  }

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
  Future<Iterable<ExtractionRecord>> allExtractions() async {
    final query = allExtractionsQuery();
    final result = await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
    return result
        .map((r) => r.toColumnMap())
        .map<ExtractionRecord>(extractionFromColumnMap);
  }

  /// Insert an extraction into the database.
  Future<void> insertExtraction(ExtractionRecord extraction) async {
    final query = insertExtractionQuery(extraction);
    await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
  }
}
