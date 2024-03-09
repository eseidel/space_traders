import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ConstructionRecord json round trip', () {
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final now = DateTime(2021);
    final record = ConstructionRecord(
      waypointSymbol: waypointSymbol,
      construction: Construction(
        isComplete: false,
        symbol: waypointSymbol.waypoint,
      ),
      timestamp: now,
    );
    final json = record.toJson();
    final record2 = ConstructionRecord.fromJson(json);
    expect(record.toJson(), record2.toJson());
  });
}
