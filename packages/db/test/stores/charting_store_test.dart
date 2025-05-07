import 'package:db/db.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../docker.dart';

void main() {
  withPostgresServer('charting store', (server) {
    test('smoke test', () async {
      final db = Database.testLive(
        endpoint: await server.endpoint(),
        connection: await server.newConnection(),
      );
      await db.migrateToLatestSchema();
      final chartingStore = ChartingStore(db);
      const waypointSymbol = WaypointSymbol.fallbackValue();
      final chart = ChartingRecord(
        waypointSymbol: waypointSymbol,
        timestamp: DateTime.timestamp(),
        values: ChartedValues.test(
          chart: Chart(
            submittedBy: 'foo',
            submittedOn: DateTime.timestamp(),
            waypointSymbol: waypointSymbol.waypoint,
          ),
        ),
      );
      await chartingStore.upsertChartingRecord(chart);
      final charts = await chartingStore.allRecords();
      expect(charts.length, 1);
      expect(charts.first, chart);

      final record = await chartingStore.chartingRecord(waypointSymbol);
      expect(record, chart);

      expect(await chartingStore.isCharted(waypointSymbol), true);
      expect(await chartingStore.chartedValues(waypointSymbol), chart.values);
    });
  });
}
