import 'package:db/query.dart';
import 'package:postgres/postgres.dart';
import 'package:types/types.dart';

/// Convert a row result into a survey.
HistoricalSurvey surveyFromResultRow(PostgreSQLResultRow row) {
  final values = row.toColumnMap();
  return HistoricalSurvey(
    survey: Survey(
      signature: values['signature'] as String,
      symbol: values['waypoint_symbol'] as String,
      deposits: (values['deposits'] as String)
          .split(',')
          .map((s) => SurveyDeposit(symbol: s))
          .toList(),
      expiration: values['expiration'] as DateTime,
      size: SurveySizeEnum.fromJson(values['size'] as String)!,
    ),
    timestamp: values['timestamp'] as DateTime,
    exhausted: values['exhausted'] as bool,
  );
}

/// Convert a survey into substitution values for a query.
Map<String, dynamic> surveyToSubstitutionValues(HistoricalSurvey survey) {
  return {
    'signature': survey.survey.signature,
    'waypoint_symbol': survey.survey.symbol,
    'deposits': survey.survey.deposits.map((e) => e.symbol).join(','),
    'expiration': survey.survey.expiration,
    'size': survey.survey.size.toJson(),
    'timestamp': survey.timestamp,
    'exhausted': survey.exhausted,
  };
}

/// Return the most recent surveys.
Query recentSurveysAtWaypointQuery({
  required WaypointSymbol waypointSymbol,
  required int count,
}) {
  return Query(
    'SELECT * FROM survey WHERE waypointSymbol = @waypointSymbol '
    'ORDER BY timestamp DESC LIMIT @count',
    substitutionValues: {
      'waypointSymbol': waypointSymbol,
      'count': count,
    },
  );
}

/// Insert a survey into the database.
Query insertSurveyQuery(HistoricalSurvey survey) {
  return Query(
    'INSERT INTO survey (signature, waypoint_symbol, deposits, expiration, '
    'size, timestamp, exhausted) VALUES (@signature, @waypointSymbol, '
    '@deposits, @expiration, @size, @timestamp, @exhausted)',
    substitutionValues: surveyToSubstitutionValues(survey),
  );
}

/// Mark a survey as exhausted.
Query markSurveyExhaustedQuery(Survey survey) {
  // "signature" is unique to the survey, "symbol" is the waypoint symbol.
  return Query(
    'UPDATE survey SET exhausted = true WHERE signature = @signature',
    substitutionValues: {
      'signature': survey.signature,
    },
  );
}
