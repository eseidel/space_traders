import 'package:cli/api.dart';
import 'package:test/test.dart';

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
    final asteroidField = SystemWaypoint(
      symbol: 'S-E-A',
      type: WaypointType.ASTEROID_FIELD,
      x: 0,
      y: 0,
    );
    expect(jumpGate.isType(WaypointType.JUMP_GATE), isTrue);
    expect(jumpGate.isJumpGate, isTrue);
    expect(jumpGate.isType(WaypointType.PLANET), isFalse);
    expect(planet.isJumpGate, isFalse);
    expect(asteroidField.isAsteroidField, isTrue);
    expect(planet.canBeMined, isFalse);
    expect(asteroidField.canBeMined, isTrue);
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
        asteroidField,
      ],
    );
    expect(system.jumpGateWaypoint, jumpGate);
  });

  test('Waypoint.hasTrait', () {
    final waypoint = Waypoint(
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
        )
      ],
    );
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.ASH_CLOUDS), isTrue);
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.BARREN), isFalse);
    final systemWaypoint = waypoint.toSystemWaypoint();
    expect(systemWaypoint.isJumpGate, isTrue);
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
}
