import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ChartingSnapshot smoke test', () async {
    final now = DateTime(2021);
    final waypointA = WaypointSymbol.fromString('S-E-A');
    final waypointB = WaypointSymbol.fromString('S-E-B');
    final snapshot = ChartingSnapshot([
      ChartingRecord(
        waypointSymbol: waypointA,
        values: ChartedValues.test(waypointSymbol: waypointA),
        timestamp: now,
      ),
      ChartingRecord(waypointSymbol: waypointB, values: null, timestamp: now),
    ]);
    expect(snapshot.records.length, 2);
    expect(snapshot.waypointCount, 2);
    expect(snapshot.values.length, 1);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-A')), isTrue);
    expect(snapshot[WaypointSymbol.fromString('S-E-A')]?.values, isNotNull);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-B')), isFalse);
    expect(snapshot.isCharted(WaypointSymbol.fromString('S-E-C')), isNull);
  });
}
