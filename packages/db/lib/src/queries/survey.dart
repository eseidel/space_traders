import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Convert a row result into a survey.
HistoricalSurvey surveyFromColumnMap(Map<String, dynamic> values) {
  return HistoricalSurvey(
    survey: Survey(
      signature: values['signature'] as String,
      symbol: values['waypoint_symbol'] as String,
      deposits:
          (values['deposits'] as List<String>)
              .map((s) => SurveyDeposit(symbol: TradeSymbol.fromJson(s)!))
              .toList(),
      expiration: values['expiration'] as DateTime,
      size: SurveySize.fromJson(values['size'] as String)!,
    ),
    timestamp: values['timestamp'] as DateTime,
    exhausted: values['exhausted'] as bool,
  );
}

/// Convert a survey into substitution values for a query.
Map<String, dynamic> surveyToColumnMap(HistoricalSurvey survey) {
  return {
    'signature': survey.survey.signature,
    'waypoint_symbol': survey.survey.symbol,
    'deposits': survey.survey.deposits.map((e) => e.symbol.value).toList(),
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
    'SELECT * FROM survey_ WHERE waypoint_symbol = @waypointSymbol '
    'ORDER BY timestamp DESC LIMIT @count',
    parameters: {'waypointSymbol': waypointSymbol.toJson(), 'count': count},
  );
}

/// Return all surveys.
Query allSurveysQuery() {
  return const Query('SELECT * FROM survey_');
}

/// Insert a survey into the database.
Query insertSurveyQuery(HistoricalSurvey survey) {
  // The server will return duplicate signatures.  When it does that we
  // just replace the one we have.
  // Insert the survey or update it if it already exists.
  return Query(
    'INSERT INTO survey_ (signature, waypoint_symbol, deposits, expiration, '
    'size, timestamp, exhausted) VALUES (@signature, @waypoint_symbol, '
    '@deposits, @expiration, @size, @timestamp, @exhausted) '
    'ON CONFLICT (signature) DO UPDATE SET '
    'waypoint_symbol = @waypoint_symbol, '
    'deposits = @deposits, '
    'expiration = @expiration, '
    'size = @size, '
    'timestamp = @timestamp, '
    'exhausted = @exhausted',
    parameters: surveyToColumnMap(survey),
  );
}

/// Mark a survey as exhausted.
Query markSurveyExhaustedQuery(Survey survey) {
  // "signature" is unique to the survey, "symbol" is the waypoint symbol.
  return Query(
    'UPDATE survey_ SET exhausted = true WHERE signature = @signature',
    parameters: {'signature': survey.signature},
  );
}
