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
  });

  test('SystemSymbol equality', () {
    final a = SystemSymbol.fromString('S-E');
    final b = SystemSymbol.fromString('S-E');
    final c = SystemSymbol.fromString('S-Q');
    expect(a, b);
    expect(a, isNot(c));
  });
  test('WaypointSymbol equality', () {
    final a = WaypointSymbol.fromString('S-E-J');
    final b = WaypointSymbol.fromString('S-E-J');
    final c = WaypointSymbol.fromString('S-E-P');
    expect(a, b);
    expect(a, isNot(c));
  });
}