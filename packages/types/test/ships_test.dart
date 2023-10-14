import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('shipTypeFromFrame', () {
    final expectedNullTypes = [
      // Two ship types use heavy freighters, so we can't map back to a type.
      ShipFrameSymbolEnum.HEAVY_FREIGHTER,
      // Unused frames:
      ShipFrameSymbolEnum.RACER,
      ShipFrameSymbolEnum.FIGHTER,
      ShipFrameSymbolEnum.TRANSPORT,
      ShipFrameSymbolEnum.DESTROYER,
      ShipFrameSymbolEnum.CRUISER,
      ShipFrameSymbolEnum.CARRIER,
    ];
    for (final frame in ShipFrameSymbolEnum.values) {
      final type = shipTypeFromFrame(frame);
      final matcher = expectedNullTypes.contains(frame) ? isNull : isNotNull;
      expect(type, matcher, reason: '$frame');
    }
  });

  test('shipFrameFromType', () {
    for (final type in ShipType.values) {
      final frame = shipFrameFromType(type);
      expect(frame, isNotNull, reason: '$type');
    }
  });
}
