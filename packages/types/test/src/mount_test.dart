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
            symbol: TradeSymbol.IRON_ORE,
            name: '',
            description: '',
            units: 1,
          ),
          ShipCargoItem(
            symbol: TradeSymbol.MOUNT_GAS_SIPHON_I,
            name: '',
            description: '',
            units: 2,
          ),
          ShipCargoItem(
            symbol: TradeSymbol.MOUNT_LASER_CANNON_I,
            name: '',
            description: '',
            units: 3,
          ),
        ],
      ),
    );
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbol.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbol.SENSOR_ARRAY_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbol.SENSOR_ARRAY_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
    ]);
    expect(
      ship.mountSymbolsInInventory,
      MountSymbolSet.from([
        ShipMountSymbol.GAS_SIPHON_I,
        ShipMountSymbol.GAS_SIPHON_I,
        ShipMountSymbol.LASER_CANNON_I,
        ShipMountSymbol.LASER_CANNON_I,
        ShipMountSymbol.LASER_CANNON_I,
      ]),
    );
    expect(
      ship.mountedMountSymbols,
      MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_II,
        ShipMountSymbol.SENSOR_ARRAY_II,
      ]),
    );

    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbol.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_III,
      ]),
    );
    expect(
      mountsToAddToShip(ship, template),
      MountSymbolSet.from([ShipMountSymbol.SENSOR_ARRAY_III]),
    );
    expect(
      mountsToRemoveFromShip(ship, template),
      MountSymbolSet.from([
        ShipMountSymbol.SENSOR_ARRAY_II,
        ShipMountSymbol.SENSOR_ARRAY_II,
      ]),
    );

    expect(template.canPurchaseAllMounts({}), isFalse);
    expect(
      template.canPurchaseAllMounts({
        ShipMountSymbol.MINING_LASER_I,
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_III,
      }),
      isTrue,
    );
  });

  test('mountsToRemoveFromShip', () {
    final ship = _MockShip();
    final mountSymbols = [
      ShipMountSymbol.MINING_LASER_II,
      ShipMountSymbol.SURVEYOR_I,
      ShipMountSymbol.MINING_LASER_II,
    ];
    ShipMount mountForSymbol(ShipMountSymbol symbol) {
      return ShipMount(
        symbol: symbol,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      );
    }

    when(
      () => ship.mounts,
    ).thenReturn(mountSymbols.map(mountForSymbol).toList());
    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbol.MINER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.MINING_LASER_I,
      ]),
    );
    final toRemove = mountsToRemoveFromShip(ship, template);
    expect(toRemove, isNotEmpty);
    expect(toRemove, MountSymbolSet.from([ShipMountSymbol.SURVEYOR_I]));
  });

  test('ShipTemplate.matches', () {
    final template = ShipTemplate(
      frameSymbol: ShipFrameSymbol.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_III,
      ]),
    );
    final ship = _MockShip();
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.FIGHTER);

    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbol.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
      ShipMount(
        symbol: ShipMountSymbol.SENSOR_ARRAY_III,
        name: '',
        description: '',
        requirements: ShipRequirements(),
      ),
    ]);
    expect(template.matches(ship), isTrue);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.EXPLORER);
    expect(template.matches(ship), isFalse);

    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.FIGHTER);
    final otherTemplate = ShipTemplate(
      frameSymbol: ShipFrameSymbol.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_II,
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
      frameSymbol: ShipFrameSymbol.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.MINING_LASER_II,
        ShipMountSymbol.SENSOR_ARRAY_III,
      ]),
    );
    final b = ShipTemplate(
      frameSymbol: ShipFrameSymbol.FIGHTER,
      mounts: MountSymbolSet.from([
        ShipMountSymbol.SENSOR_ARRAY_III,
        ShipMountSymbol.MINING_LASER_II,
      ]),
    );
    expect(a, equals(a));
    expect(a.hashCode, equals(a.hashCode));
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('ShipTemplate.mountsSymbolSetEquals', () {
    final a = MountSymbolSet.from([
      ShipMountSymbol.MINING_LASER_II,
      ShipMountSymbol.SENSOR_ARRAY_III,
    ]);
    final b = MountSymbolSet.from([
      ShipMountSymbol.SENSOR_ARRAY_III,
      ShipMountSymbol.MINING_LASER_II,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, b), isTrue);
    expect(ShipTemplate.mountsSymbolSetEquals(a, MountSymbolSet()), isFalse);
    expect(ShipTemplate.mountsSymbolSetEquals(MountSymbolSet(), a), isFalse);

    final c = MountSymbolSet.from([
      ShipMountSymbol.GAS_SIPHON_I,
      ShipMountSymbol.MINING_LASER_II,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, c), isFalse);
    final d = MountSymbolSet.from([
      ShipMountSymbol.MINING_LASER_II,
      ShipMountSymbol.SENSOR_ARRAY_III,
      ShipMountSymbol.SENSOR_ARRAY_III,
    ]);
    expect(ShipTemplate.mountsSymbolSetEquals(a, d), isFalse);
  });

  test('MountRequest', () {
    const shipSymbol = ShipSymbol('S', 1);
    const mountSymbol = ShipMountSymbol.MINING_LASER_II;
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
