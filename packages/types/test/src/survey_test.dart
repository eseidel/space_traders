import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('HistoricalSurvey roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final survey = HistoricalSurvey(
      exhausted: true,
      survey: Survey(
        symbol: 'MOON',
        signature: 'sig',
        expiration: moonLanding,
        size: SurveySize.SMALL,
        deposits: [SurveyDeposit(symbol: TradeSymbol.DIAMONDS)],
      ),
      timestamp: moonLanding,
    );
    final json = survey.toJson();
    final survey2 = HistoricalSurvey.fromJson(json);
    final json2 = survey2.toJson();
    // Despite HistoricalSurvey being immutable, Survey isn't so we
    // can't write a working equals for HistoricalSurvey.
    expect(survey2 != survey, true);
    // But the json generated should be identical.
    expect(json2, json);
  });
}
