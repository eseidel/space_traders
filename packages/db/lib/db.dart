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
    timeoutInSeconds: 1,
  );
  await connection.open();
  return Database(connection);
}

/// Abstraction around a database connection.
class Database {
  /// Create a new database connection.
  Database(this.connection);

  /// Insert a transaction into the database.
  Future<void> insertTransaction(TransactionRecord record) async {
    final query = insertTransactionQuery(record);
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
}
