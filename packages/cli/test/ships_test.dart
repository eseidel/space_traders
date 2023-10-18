import 'package:cli/cache/static_cache.dart';
import 'package:cli/ships.dart';
import 'package:file/local.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  final shipyardShips = ShipyardShipCache.load(const LocalFileSystem());

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
      // TODO(eseidel): Remove this once we have data on COMMAND_FRIGATE
      if (frame == ShipFrameSymbolEnum.FRIGATE) {
        continue;
      }

      final type = shipyardShips.shipTypeFromFrame(frame);
      final matcher = expectedNullTypes.contains(frame) ? isNull : isNotNull;
      expect(type, matcher, reason: 'no shipType with frame $frame');
    }
  });

  test('shipFrameFromType', () {
    for (final type in ShipType.values) {
      // TODO(eseidel): Remove this once we have data on COMMAND_FRIGATE
      if (type == ShipType.COMMAND_FRIGATE) {
        continue;
      }

      final frame = shipyardShips.shipFrameFromType(type);
      expect(frame, isNotNull, reason: 'no frame for type $type');
    }
  });
}
