import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('SystemWaypoint.isType', () {
    final jumpGate = SystemWaypoint.test(
      WaypointSymbol.fromString('S-E-J'),
      type: WaypointType.JUMP_GATE,
    );
    final planet = SystemWaypoint.test(
      WaypointSymbol.fromString('S-E-P'),
      type: WaypointType.PLANET,
    );
    final asteroid = SystemWaypoint.test(WaypointSymbol.fromString('S-E-A'));
    expect(jumpGate.isType(WaypointType.JUMP_GATE), isTrue);
    expect(jumpGate.isJumpGate, isTrue);
    expect(jumpGate.isType(WaypointType.PLANET), isFalse);
    expect(asteroid.isAsteroid, isTrue);
    expect(jumpGate.system, SystemSymbol.fromString('S-E'));

    final system = System.test(
      SystemSymbol.fromString('S-E'),
      waypoints: [jumpGate, planet, asteroid],
    );
    expect(system.jumpGateWaypoints.first, jumpGate);
  });

  test('Waypoint.hasTrait', () {
    final waypoint = Waypoint.test(
      WaypointSymbol.fromString('S-E-J'),
      type: WaypointType.JUMP_GATE,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.ASH_CLOUDS,
          name: '',
          description: '',
        ),
      ],
    );
    expect(waypoint.hasTrait(WaypointTraitSymbol.ASH_CLOUDS), isTrue);
    expect(waypoint.hasTrait(WaypointTraitSymbol.BARREN), isFalse);
    final systemWaypoint = waypoint.toSystemWaypoint();
    expect(systemWaypoint.symbol, waypoint.symbol);
  });

  test('SystemWaypoint json roundtrip', () {
    final waypoint = SystemWaypoint.test(
      WaypointSymbol.fromString('S-E-J'),
      type: WaypointType.JUMP_GATE,
    );
    final json = waypoint.toJson();
    final fromJson = SystemWaypoint.fromJson(json);
    // SystemWaypoint doesn't have an equals method, so compare the json.
    expect(fromJson.toJson(), waypoint.toJson());
  });

  test('Waypoint json round trip', () {
    final waypoint = Waypoint.test(
      WaypointSymbol.fromString('S-E-J'),
      type: WaypointType.JUMP_GATE,
      traits: [
        WaypointTrait(
          symbol: WaypointTraitSymbol.ASH_CLOUDS,
          name: '',
          description: '',
        ),
      ],
    );
    final json = waypoint.toJson();
    final fromJson = Waypoint.fromJson(json);
    // Waypoint doesn't have an equals method, so compare the json.
    expect(fromJson.toJson(), waypoint.toJson());
  });

  test('System json round trip', () {
    final system = System.test(
      SystemSymbol.fromString('S-E'),
      waypoints: [
        SystemWaypoint.test(
          WaypointSymbol.fromString('S-E-J'),
          type: WaypointType.JUMP_GATE,
        ),
      ],
    );
    final json = system.toJson();
    final fromJson = System.fromJson(json);
    // System doesn't have an equals method, so compare the json.
    expect(fromJson.toJson(), system.toJson());
  });
}
