import 'package:types/api.dart';

const _typeFramePairs = [
  (ShipType.PROBE, ShipFrameSymbolEnum.PROBE),
  (ShipType.MINING_DRONE, ShipFrameSymbolEnum.DRONE),
  (ShipType.INTERCEPTOR, ShipFrameSymbolEnum.INTERCEPTOR),
  (ShipType.LIGHT_HAULER, ShipFrameSymbolEnum.LIGHT_FREIGHTER),
  (ShipType.COMMAND_FRIGATE, ShipFrameSymbolEnum.FRIGATE),
  (ShipType.EXPLORER, ShipFrameSymbolEnum.EXPLORER),
  (ShipType.HEAVY_FREIGHTER, ShipFrameSymbolEnum.HEAVY_FREIGHTER),
  (ShipType.LIGHT_SHUTTLE, ShipFrameSymbolEnum.SHUTTLE),
  (ShipType.ORE_HOUND, ShipFrameSymbolEnum.MINER),
  (ShipType.REFINING_FREIGHTER, ShipFrameSymbolEnum.HEAVY_FREIGHTER),
];

/// Map from ship type to ship frame symbol.
ShipType? shipTypeFromFrame(ShipFrameSymbolEnum frame) {
  ShipType? shipType;
  for (final pair in _typeFramePairs) {
    if (pair.$2 != frame) {
      continue;
    }
    if (shipType != null) {
      // Multiple frames map to the same ship type.
      return null;
    }
    shipType = pair.$1;
  }
  return shipType;
}

/// Map from ship type to ship frame symbol.
ShipFrameSymbolEnum? shipFrameFromType(ShipType type) {
  for (final pair in _typeFramePairs) {
    if (pair.$1 == type) return pair.$2;
  }
  return null;
}
