import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('survey_store', (server) {
    group('foo', () {
      late Database db;
      setUpAll(() async {
        final endpoint = await server.endpoint();
        db = Database.testLive(
          endpoint: endpoint,
          connection: await server.newConnection(),
        );
        await db.migrateToLatestSchema();
      });

      setUp(() async {
        await db.migrateToSchema(version: 0);
        await db.migrateToLatestSchema();
      });

      test('insert', () async {
        final now = DateTime.timestamp();
        final waypoint = WaypointSymbol.fromString('X1-B-4');
        const symbol = TradeSymbol.DIAMONDS;
        final survey = HistoricalSurvey(
          timestamp: now,
          exhausted: false,
          survey: Survey(
            signature: '123',
            symbol: waypoint.waypoint,
            size: SurveySizeEnum.SMALL,
            deposits: [SurveyDeposit(symbol: symbol.value)],
            expiration: now.add(const Duration(days: 1)),
          ),
        );
        await db.surveys.insert(survey);

        final surveys = await db.surveys.all();
        expect(surveys.length, 1);
        expect(surveys.first.survey.deposits.first.symbol, symbol.value);

        final recent = await db.surveys.recentAt(waypoint, count: 100);
        expect(recent.length, 1);
        expect(recent.first.survey.deposits.first.symbol, symbol.value);

        expect(recent.first.exhausted, false);

        await db.surveys.markExhausted(survey.survey);
        final exhausted = await db.surveys.all();
        expect(exhausted.first.exhausted, true);
      });
    });
  });
}
