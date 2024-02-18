import 'package:db/src/construction.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ConstructionRecord round trip', () {
    final waypointSymbol = WaypointSymbol.fromString('S-E-A');
    final record = ConstructionRecord(
      timestamp: DateTime(2021),
      waypointSymbol: waypointSymbol,
      construction: Construction(
        symbol: waypointSymbol.waypoint,
        materials: [
          ConstructionMaterial(
            tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
            required_: 100,
            fulfilled: 10,
          ),
        ],
        isComplete: false,
      ),
    );
    final map = constructionToColumnMap(record);
    final newRecord = constructionFromColumnMap(map);
    expect(record.timestamp, equals(newRecord.timestamp));
    expect(record.waypointSymbol, equals(newRecord.waypointSymbol));
    // == won't work for Construction or ConstructionRecord.
  });
}
