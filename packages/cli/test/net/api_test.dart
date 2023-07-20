import 'package:cli/api.dart';
import 'package:test/test.dart';

void main() {
  test('parseWaypointString', () {
    final parsed = parseWaypointString('X1-DF55-20250Z');
    expect(parsed.sector, 'X1');
    expect(parsed.system, 'X1-DF55');
    expect(parsed.waypoint, 'X1-DF55-20250Z');
  });

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
}
