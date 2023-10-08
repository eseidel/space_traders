import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

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

  test('mountsToRemoveFromShip', () {
    final ship = _MockShip();
    final mountSymbols = [
      ShipMountSymbolEnum.MINING_LASER_II,
      ShipMountSymbolEnum.SURVEYOR_I,
      ShipMountSymbolEnum.MINING_LASER_II,
    ];
    ShipMount mountForSymbol(ShipMountSymbolEnum symbol) {
      return ShipMount(
        symbol: symbol,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      );
    }

    when(() => ship.mounts)
        .thenReturn(mountSymbols.map(mountForSymbol).toList());
    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.MINER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.MINING_LASER_I,
      ]),
    );
    final toRemove = mountsToRemoveFromShip(ship, template);
    expect(toRemove, isNotEmpty);
    expect(toRemove, MountSymbolSet.from([ShipMountSymbolEnum.SURVEYOR_I]));
  });

  test('ShipTemplate.matches', () {
    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ]),
    );
    final ship = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);

    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbolEnum.SENSOR_ARRAY_III,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
    ]);
    expect(template.matches(ship), isTrue);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.EXPLORER);
    expect(template.matches(ship), isFalse);

    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final otherTemplate = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_II,
      ]),
    );
    expect(otherTemplate.matches(ship), isFalse);

    final emptyShip = _MockShip();
    when(() => emptyShip.frame).thenReturn(shipFrame);
    when(() => emptyShip.mounts).thenReturn([]);
    expect(template.matches(emptyShip), isFalse);
  });

  test('ShipTemplate equality', () {
    final a = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.MINING_LASER_II,
        ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ]),
    );
    final b = ShipTemplate(
      frameSymbol: ShipFrameSymbolEnum.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbolEnum.SENSOR_ARRAY_III,
        ShipMountSymbolEnum.MINING_LASER_II,
      ]),
    );
    expect(a, equals(a));
    expect(a.hashCode, equals(a.hashCode));
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('ShipTemplate.mountsSymbolSetEquals', () {
    final a = MountSymbolSet.from([
      ShipMountSymbolEnum.MINING_LASER_II,
      ShipMountSymbolEnum.SENSOR_ARRAY_III,
    ]);
    final b = MountSymbolSet.from([
      ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ShipMountSymbolEnum.MINING_LASER_II,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, b), isTrue);
    expect(ShipTemplate.mountsSymbolSetEquals(a, MountSymbolSet()), isFalse);
    expect(ShipTemplate.mountsSymbolSetEquals(MountSymbolSet(), a), isFalse);

    final c = MountSymbolSet.from([
      ShipMountSymbolEnum.GAS_SIPHON_I,
      ShipMountSymbolEnum.MINING_LASER_II,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, c), isFalse);
    final d = MountSymbolSet.from([
      ShipMountSymbolEnum.MINING_LASER_II,
      ShipMountSymbolEnum.SENSOR_ARRAY_III,
      ShipMountSymbolEnum.SENSOR_ARRAY_III,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, d), isFalse);
  });

  test('MountRequest', () {
    const shipSymbol = ShipSymbol('S', 1);
    const mountSymbol = ShipMountSymbolEnum.MINING_LASER_II;
    final marketSymbol = WaypointSymbol.fromString('M-A-R');
    final shipyardSymbol = WaypointSymbol.fromString('S-A-B');
    const creditsNeeded = 100000;
    final request = MountRequest(
      shipSymbol: shipSymbol,
      mountSymbol: mountSymbol,
      marketSymbol: marketSymbol,
      shipyardSymbol: shipyardSymbol,
      creditsNeeded: creditsNeeded,
    );
    final buyJob = request.buyJob;
    expect(buyJob.tradeSymbol, equals(tradeSymbolForMountSymbol(mountSymbol)));
    expect(buyJob.units, equals(1));
    expect(buyJob.buyLocation, equals(marketSymbol));
    final mountJob = request.mountJob;
    expect(mountJob.mountSymbol, equals(mountSymbol));
    expect(mountJob.shipyardSymbol, equals(shipyardSymbol));
  });
}
