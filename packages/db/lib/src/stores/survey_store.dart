import 'package:db/db.dart';
import 'package:db/src/queries/survey.dart';
import 'package:types/types.dart';

/// Store for surveys.
class SurveyStore {
  /// Create a new survey store.
  SurveyStore(this._db);

  final Database _db;

  /// Insert a survey into the database.
  Future<void> insert(HistoricalSurvey survey) async {
    await _db.execute(insertSurveyQuery(survey));
  }

  /// Return the most recent surveys.
  Future<Iterable<HistoricalSurvey>> recentAt(
    WaypointSymbol waypointSymbol, {
    required int count,
  }) async {
    final query = recentSurveysAtWaypointQuery(
      waypointSymbol: waypointSymbol,
      count: count,
    );
    return _db.queryMany(query, surveyFromColumnMap);
  }

  /// Return all surveys.
  Future<Iterable<HistoricalSurvey>> all() async =>
      _db.queryMany(allSurveysQuery(), surveyFromColumnMap);

  /// Mark the given survey as exhausted.
  Future<void> markExhausted(Survey survey) async {
    final query = markSurveyExhaustedQuery(survey);
    final result = await _db.execute(query);
    if (result.affectedRows != 1) {
      throw ArgumentError('Survey not found: $survey');
    }
  }
}
