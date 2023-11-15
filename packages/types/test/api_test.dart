import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShip extends Mock implements Ship {}

void main() {
  test('SystemWaypoint.isType', () {
    final jumpGate = SystemWaypoint(
      symbol: 'S-E-J',
      type: WaypointType.JUMP_GATE,
      x: 0,
      y: 0,
    );
    final planet = SystemWaypoint(
      symbol: 'S-E-P',
      type: WaypointType.PLANET,
      x: 0,
      y: 0,
    );
    final asteroid = SystemWaypoint(
      symbol: 'S-E-A',
      type: WaypointType.ASTEROID,
      x: 0,
      y: 0,
    );
    expect(jumpGate.isType(WaypointType.JUMP_GATE), isTrue);
    expect(jumpGate.isType(WaypointType.PLANET), isFalse);
    expect(asteroid.isAsteroid, isTrue);
    expect(jumpGate.systemSymbol, SystemSymbol.fromString('S-E'));

    final system = System(
      symbol: 'S-E',
      sectorSymbol: 'S',
      type: SystemType.BLUE_STAR,
      x: 0,
      y: 0,
      waypoints: [
        jumpGate,
        planet,
        asteroid,
      ],
    );
    expect(system.jumpGateWaypoint, jumpGate);
  });

  test('Waypoint.hasTrait', () {
    final waypoint = Waypoint(
      isUnderConstruction: false,
      symbol: 'S-E-J',
      systemSymbol: 'S-E',
      type: WaypointType.JUMP_GATE,
      x: 0,
      y: 0,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbolEnum.ASH_CLOUDS,
          name: '',
          description: '',
        ),
      ],
    );
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.ASH_CLOUDS), isTrue);
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.BARREN), isFalse);
    final systemWaypoint = waypoint.toSystemWaypoint();
    expect(systemWaypoint.symbol, waypoint.symbol);
  });

  test('SystemSymbol equality', () {
    final a = SystemSymbol.fromString('S-E');
    final b = SystemSymbol.fromString('S-E');
    final c = SystemSymbol.fromString('S-Q');
    expect(a, b);
    expect(a, isNot(c));
    expect(a.sector, 'S');

    expect(() => SystemSymbol.fromString('S'), throwsArgumentError);
    expect(() => SystemSymbol.fromString('S-E-A'), throwsArgumentError);
  });
  test('WaypointSymbol equality', () {
    final a = WaypointSymbol.fromString('S-E-J');
    final b = WaypointSymbol.fromString('S-E-J');
    final c = WaypointSymbol.fromString('S-E-P');
    expect(a, b);
    expect(a, isNot(c));
    expect(a.sector, 'S');
    expect(a.system, 'S-E');

    expect(() => WaypointSymbol.fromString('S-E'), throwsArgumentError);
    expect(() => WaypointSymbol.fromString('S-E-A-F'), throwsArgumentError);
  });
  test('WaypointPosition distance', () {
    final system = SystemSymbol.fromString('S-E');
    final a = WaypointPosition(0, 0, system);
    final b = WaypointPosition(3, 4, system);
    expect(a.distanceTo(b), 5);
    expect(b.distanceTo(a), 5);
    final c = WaypointPosition(3, 0, SystemSymbol.fromString('S-F'));
    expect(() => a.distanceTo(c), throwsArgumentError);
  });
  test('ShipSymbol sorting', () {
    final symbols = [
      ShipSymbol.fromString('A-1A'),
      ShipSymbol.fromString('A-A'),
      ShipSymbol.fromString('A-2'),
      const ShipSymbol('A', 1),
    ]..sort();
    expect(symbols, [
      const ShipSymbol('A', 1),
      ShipSymbol.fromString('A-2'),
      ShipSymbol.fromString('A-A'),
      ShipSymbol.fromString('A-1A'),
    ]);
  });
  test('ShipSymbol agentName with hyphen', () {
    final symbol = ShipSymbol.fromString('A-1-A');
    expect(symbol.agentName, 'A-1');
  });

  test('FactionUtils', () {
    final faction = Faction(
      description: '',
      symbol: FactionSymbols.AEGIS,
      name: '',
      headquarters: 'S-A-W',
      traits: [],
      isRecruiting: true,
    );
    expect(faction.headquartersSymbol, WaypointSymbol.fromString('S-A-W'));
  });
  test('AgentUtils', () {
    final agent = Agent(
      symbol: 'A-1',
      headquarters: 'S-A-W',
      credits: 0,
      startingFaction: FactionSymbols.AEGIS.value,
    );
    expect(agent.headquartersSymbol, WaypointSymbol.fromString('S-A-W'));
  });
  test('tradeSymbolForMountSymbol', () {
    for (final mountSymbol in ShipMountSymbolEnum.values) {
      final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
      expect(mountSymbolForTradeSymbol(tradeSymbol), mountSymbol);
    }
    // Non-mount symbols will fail however:
    expect(mountSymbolForTradeSymbol(TradeSymbol.ADVANCED_CIRCUITRY), isNull);
  });

  test('isMinableTrait', () {
    final minable =
        WaypointTraitSymbolEnum.values.where(isMinableTrait).toList();
    expect(minable, [
      WaypointTraitSymbolEnum.MINERAL_DEPOSITS,
      WaypointTraitSymbolEnum.COMMON_METAL_DEPOSITS,
      WaypointTraitSymbolEnum.PRECIOUS_METAL_DEPOSITS,
      WaypointTraitSymbolEnum.RARE_METAL_DEPOSITS,
    ]);
  });

  test('updateCacheWithAddedCargo', () {
    final ship = _MockShip();
    when(() => ship.cargo).thenReturn(ShipCargo(capacity: 100, units: 0));
    ship.updateCacheWithAddedCargo(TradeSymbol.ADVANCED_CIRCUITRY, 2);
    expect(ship.cargo.units, 2);
    expect(ship.cargo.inventory.length, 1);
    expect(ship.cargo.inventory.first.symbol, TradeSymbol.ADVANCED_CIRCUITRY);
    expect(ship.cargo.inventory.first.units, 2);

    ship.updateCacheWithAddedCargo(TradeSymbol.ADVANCED_CIRCUITRY, 3);
    expect(ship.cargo.units, 5);
    expect(ship.cargo.inventory.length, 1);
    expect(ship.cargo.inventory.first.symbol, TradeSymbol.ADVANCED_CIRCUITRY);
    expect(ship.cargo.inventory.first.units, 5);

    ship.updateCacheWithAddedCargo(TradeSymbol.ALUMINUM, 3);
    expect(ship.cargo.units, 8);
    expect(ship.cargo.inventory.length, 2);
    expect(ship.cargo.inventory.first.symbol, TradeSymbol.ADVANCED_CIRCUITRY);
    expect(ship.cargo.inventory.first.units, 5);
    expect(ship.cargo.inventory.last.symbol, TradeSymbol.ALUMINUM);
    expect(ship.cargo.inventory.last.units, 3);

    expect(
      () => ship.updateCacheWithAddedCargo(TradeSymbol.ALUMINUM, 100),
      throwsArgumentError,
    );
  });
}
