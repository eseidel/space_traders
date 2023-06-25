import 'package:cli/api.dart';
import 'package:cli/cache/surveys.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('HistoricalSurvey roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final survey = HistoricalSurvey(
      exhausted: true,
      survey: Survey(
        symbol: 'MOON',
        signature: 'sig',
        expiration: moonLanding,
        size: SurveySizeEnum.SMALL,
        deposits: [
          SurveyDeposit(
            symbol: 'DIAMONDS',
          ),
        ],
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

  test('SurveyData load/save', () async {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final fs = MemoryFileSystem.test();
    final survey = HistoricalSurvey(
      exhausted: true,
      survey: Survey(
        symbol: 'MOON',
        signature: 'sig',
        expiration: moonLanding,
        size: SurveySizeEnum.SMALL,
        deposits: [
          SurveyDeposit(
            symbol: 'DIAMONDS',
          ),
        ],
      ),
      timestamp: moonLanding,
    );
    final surveys = [survey];
    final surveyData = SurveyData(surveys: surveys, fs: fs);
    await surveyData.save();
    final surveyData2 = await SurveyData.load(fs);
    expect(surveyData2.surveys.length, surveys.length);
    // Could also json compare.
  });
}
