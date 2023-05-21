import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/data_store.dart';
import 'package:test/test.dart';

void main() {
  test('surveySetToJson', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final survey = Survey(
      signature: 'a',
      symbol: 'a',
      expiration: moonLanding,
      size: SurveySizeEnum.SMALL,
      deposits: [SurveyDeposit(symbol: 'a')],
    );
    final surveySet = SurveySet(waypointSymbol: 'a', surveys: [survey]);
    expect(surveySet.toJson(), <String, dynamic>{
      'waypointSymbol': 'a',
      'surveys': [
        {
          'signature': 'a',
          'symbol': 'a',
          'deposits': [
            {'symbol': 'a'}
          ],
          'expiration': '1969-07-20T20:18:04.000Z',
          'size': 'SMALL'
        }
      ]
    });
  });
}
