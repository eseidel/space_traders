import 'package:cli/cache/charting_cache.dart';
import 'package:db/chart.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ChartingSnapshot smoke test', () async {
    final now = DateTime(2021);
    final snapshot = ChartingSnapshot(
      [
        ChartingRecord(
          waypointSymbol: WaypointSymbol.fromString('S-E-A'),
          values: ChartedValues.test(),
          timestamp: now,
        ),
        ChartingRecord(
          waypointSymbol: WaypointSymbol.fromString('S-E-B'),
          values: ChartedValues.test(),
          timestamp: now,
        ),
      ],
    );
    expect(snapshot.records.length, 2);
    expect(snapshot.waypointCount, 2);
  });
}
