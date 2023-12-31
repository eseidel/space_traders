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
          values: null,
          timestamp: now,
        ),
      ],
    );
    expect(snapshot.records.length, 2);
    expect(snapshot.waypointCount, 2);
    expect(snapshot.values.length, 1);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-A')), isTrue);
    expect(snapshot[WaypointSymbol.fromString('S-E-A')]?.values, isNotNull);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-B')), isFalse);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-C')), isNull);
  });
}
