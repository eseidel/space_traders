import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

void main() {
  test('Mount extensions', () {
    final ship = _MockShip();
    when(() => ship.cargo).thenReturn(
      ShipCargo(
        capacity: 100,
        units: 6,
        inventory: [
          ShipCargoItem(
            symbol: TradeSymbol.IRON_ORE.value,
            name: '',
            description: '',
            units: 1,
          ),
          ShipCargoItem(
            symbol: TradeSymbol.MOUNT_GAS_SIPHON_I.value,
            name: '',
            description: '',
            units: 2,
          ),
          ShipCargoItem(
            symbol: TradeSymbol.MOUNT_LASER_CANNON_I.value,
            name: '',
            description: '',
            units: 3,
          ),
        ],
      ),
    );
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbolEnum.SENSOR_ARRAY_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbolEnum.SENSOR_ARRAY_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
    ]);
    expect(
      ship.mountSymbolsInInventory,
      MountSymbolSet.from([
        ShipMountSymbolEnum.GAS_SIPHON_I,
        ShipMountSymbolEnum.GAS_SIPHON_I,
        ShipMountSymbolEnum.LASER_CANNON_I,
        ShipMountSymbolEnum.LASER_CANNON_I,
        ShipMountSymbolEnum.LASER_CANNON_I,
      ]),
    );
    expect(
      ship.mountedMountSymbols,
      MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_II,
      ]),
    );

    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ]),
    );
    expect(
      mountsToAddToShip(ship, template),
      MountSymbolSet.from([
        ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ]),
    );
    expect(
      mountsToRemoveFromShip(ship, template),
      MountSymbolSet.from([
        ShipMountSymbolEnum.SENSOR_ARRAY_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_II,
      ]),
    );
  });
}
