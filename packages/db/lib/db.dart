import 'package:db/agent.dart';
import 'package:db/extraction.dart';
import 'package:db/faction.dart';
import 'package:db/survey.dart';
import 'package:db/transaction.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Connect to the default local database.
/// Logs and returns null on failure.
Future<Database> defaultDatabase() async {
  final connection = PostgreSQLConnection(
    'localhost',
    5432,
    'spacetraders',
    username: 'postgres',
    password: 'password',
  );
  await connection.open();
  return Database(connection);
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.connection);

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
  final PostgreSQLConnection connection;

  /// Open the database connection.
  Future<void> open() => connection.open();

  /// Close the database connection.
  Future<void> close() => connection.close();

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
    return result.map<HistoricalSurvey>(surveyFromResultRow);
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
        .then((result) => factionFromResultRow(result.first));
  }

  /// Gets all factions.
  Future<List<Faction>> allFactions() {
    final query = allFactionsQuery();
    return connection
        .query(query.fmtString, substitutionValues: query.substitutionValues)
        .then((result) => result.map(factionFromResultRow).toList());
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

  /// Insert an extraction into the database.
  Future<void> insertExtraction(ExtractionRecord extraction) async {
    final query = insertExtractionQuery(extraction);
    await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
  }

  /// Loads my cached agent.
  Future<Agent?> myCachedAgent() async {
    final query = myCachedAgentQuery();
    final result = await connection.query(
      query.fmtString,
      substitutionValues: query.substitutionValues,
    );
    if (result.isEmpty) {
      return null;
    }
    return agentFromResultRow(result.first);
  }
}
