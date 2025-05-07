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
      final waypointSymbol = WaypointSymbol.fromString('X1-A-W');
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
      expect(charts.first.waypointSymbol, waypointSymbol);

      final record = await chartingStore.chartingRecord(waypointSymbol);
      expect(record?.waypointSymbol, waypointSymbol);

      expect(await chartingStore.isCharted(waypointSymbol), true);

      final values = await chartingStore.chartedValues(waypointSymbol);
      expect(values?.traitSymbols, chart.values?.traitSymbols);

      final waypointSymbol2 = WaypointSymbol.fromString('X1-A-Y');
      await chartingStore.addWaypoints([
        Waypoint.test(waypointSymbol),
        Waypoint.test(waypointSymbol2, chart: Chart(submittedBy: 'bar')),
      ]);

      final snapshot = await chartingStore.snapshotAllRecords();
      expect(snapshot.records.length, 2);
      expect(snapshot.records.first.waypointSymbol, waypointSymbol);
      expect(snapshot.records.last.waypointSymbol, waypointSymbol2);
    });
  });
}
