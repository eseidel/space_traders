import 'package:cli/cache/static_cache.dart';
import 'package:cli/plan/ships.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  final shipyardShips = ShipyardShipCache.load(const LocalFileSystem());

  test('shipTypeFromFrame', () {
    final expectedNullTypes = [
      // Two ship types use heavy freighters, so we can't map back to a type.
      ShipFrameSymbolEnum.HEAVY_FREIGHTER,
      // Two ship types use drone, so we can't map back to a type.
      ShipFrameSymbolEnum.DRONE,
      // Unused frames:
      ShipFrameSymbolEnum.RACER,
      ShipFrameSymbolEnum.FIGHTER,
      ShipFrameSymbolEnum.TRANSPORT,
      ShipFrameSymbolEnum.DESTROYER,
      ShipFrameSymbolEnum.CRUISER,
      ShipFrameSymbolEnum.CARRIER,
      ShipFrameSymbolEnum.BULK_FREIGHTER,
    ];
    for (final frame in ShipFrameSymbolEnum.values) {
      final type = shipyardShips.shipTypeFromFrame(frame);
      final matcher = expectedNullTypes.contains(frame) ? isNull : isNotNull;
      expect(type, matcher, reason: 'no shipType with frame $frame');
    }
  });

  test('shipFrameFromType', () {
    // We haven't come across this type yet, once we do, remove this.
    final expectedNullTypes = [ShipType.BULK_FREIGHTER];
    for (final type in ShipType.values) {
      final frame = shipyardShips.shipFrameFromType(type);
      final matcher = expectedNullTypes.contains(type) ? isNull : isNotNull;
      expect(frame, matcher, reason: 'no frame for type $type');
    }
  });

  test('makeShip crew', () {
    final ship = shipyardShips.shipForTest(ShipType.ORE_HOUND);
    expect(ship!.crew.current, 33);
    // Also check COMMAND_FRIGATE has 59 crew.
  });
}
