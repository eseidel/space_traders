import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ChartingRecord json round trip', () {
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final now = DateTime(2021);
    final record = ChartingRecord(
      waypointSymbol: waypointSymbol,
      values: ChartedValues(
        faction: WaypointFaction(symbol: FactionSymbol.AEGIS),
        traitSymbols: const {
          WaypointTraitSymbol.ASH_CLOUDS,
          WaypointTraitSymbol.BARREN,
        },
        chart: Chart(
          waypointSymbol: waypointSymbol.waypoint,
          submittedBy: 'foo',
          submittedOn: now,
        ),
      ),
      timestamp: now,
    );
    final json = record.toJson();
    final record2 = ChartingRecord.fromJson(json);
    expect(record.toJson(), record2.toJson());
  });
}
