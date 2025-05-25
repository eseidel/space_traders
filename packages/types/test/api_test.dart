import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipyardShip extends Mock implements ShipyardShip {}

void main() {
  test('ShipUtils smoke test', () {
    // None of these are great tests, just appeasing coverage.
    final ship = _MockShip();
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    expect(ship.isFuelFull, isTrue);
    expect(ship.fuelUnitsNeeded, 0);

    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.CARRIER);
    expect(ship.isExplorer, isFalse);

    when(() => ship.modules).thenReturn([]);
    when(() => ship.mounts).thenReturn([]);
    expect(ship.hasMiningLaser, isFalse);
    expect(ship.hasSiphon, isFalse);
    expect(ship.hasOreRefinery, isFalse);
  });

  test('ShipyardShipUtils', () {
    final ship = _MockShipyardShip();
    when(() => ship.modules).thenReturn([]);
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.fuelCapacity).thenReturn(100);
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipEngine.speed).thenReturn(1);
    final shipSpec = ship.shipSpec;
    expect(shipSpec.fuelCapacity, 100);
    expect(shipSpec.speed, 1);
    expect(shipSpec.cargoCapacity, 0);
    expect(shipSpec.canWarp, isFalse);
  });

  test('FactionUtils', () {
    final faction = Faction(
      description: '',
      symbol: FactionSymbol.AEGIS,
      name: '',
      headquarters: 'S-A-W',
      traits: [],
      isRecruiting: true,
    );
    expect(faction.headquartersSymbol, WaypointSymbol.fromString('S-A-W'));
  });
  test('CargoUtils', () {
    final cargo = ShipCargo(
      capacity: 100,
      units: 2,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          name: '',
          description: '',
          units: 2,
        ),
      ],
    );
    expect(cargo.countUnits(TradeSymbol.ADVANCED_CIRCUITRY), 2);
    expect(cargo.countUnits(TradeSymbol.ALUMINUM), 0);
    expect(cargo.isEmpty, isFalse);
    expect(cargo.isNotEmpty, isTrue);
    expect(cargo.availableSpace, 98);
  });

  test('tradeSymbolForMountSymbol', () {
    for (final mountSymbol in ShipMountSymbol.values) {
      final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
      expect(mountSymbolForTradeSymbol(tradeSymbol), mountSymbol);
    }
    // Non-mount symbols will fail however:
    expect(
      () => mountSymbolForTradeSymbol(TradeSymbol.ADVANCED_CIRCUITRY),
      throwsA(isA<FormatException>()),
    );
  });

  test('isMinableTrait', () {
    final minable = WaypointTraitSymbol.values.where(isMinableTrait).toList();
    expect(minable, [
      WaypointTraitSymbol.MINERAL_DEPOSITS,
      WaypointTraitSymbol.COMMON_METAL_DEPOSITS,
      WaypointTraitSymbol.PRECIOUS_METAL_DEPOSITS,
      WaypointTraitSymbol.RARE_METAL_DEPOSITS,
    ]);
  });
}
