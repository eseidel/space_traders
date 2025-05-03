import 'package:db/src/queries/survey.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('Survey round trip', () {
    final survey = HistoricalSurvey(
      timestamp: DateTime(2021),
      survey: Survey(
        signature: 'foo',
        symbol: 'bar',
        deposits: [],
        expiration: DateTime(2021),
        size: SurveySizeEnum.LARGE,
      ),
      exhausted: false,
    );
    final map = surveyToColumnMap(survey);
    final newSurvey = surveyFromColumnMap(map);
    expect(survey.timestamp, equals(newSurvey.timestamp));
  });
}
