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
      await db.charting.upsertChartingRecord(chart);
      final charts = await db.charting.allRecords();
      expect(charts.length, 1);
      expect(charts.first.waypointSymbol, waypointSymbol);

      final record = await db.charting.chartingRecord(waypointSymbol);
      expect(record?.waypointSymbol, waypointSymbol);

      expect(await db.charting.isCharted(waypointSymbol), true);

      final values = await db.charting.chartedValues(waypointSymbol);
      expect(values?.traitSymbols, chart.values?.traitSymbols);

      final waypointSymbol2 = WaypointSymbol.fromString('X1-A-Y');
      await db.charting.addWaypoints([
        Waypoint.test(waypointSymbol),
        Waypoint.test(
          waypointSymbol2,
          chart: Chart(
            waypointSymbol: waypointSymbol2.waypoint,
            submittedBy: 'bar',
            submittedOn: DateTime.timestamp(),
          ),
        ),
      ]);

      final snapshot = await db.charting.snapshotAllRecords();
      expect(snapshot.records.length, 2);
      expect(snapshot.records.first.waypointSymbol, waypointSymbol);
      expect(snapshot.records.last.waypointSymbol, waypointSymbol2);
    });
  });
}
