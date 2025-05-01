import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('SystemSymbol equality', () {
    final a = SystemSymbol.fromString('S-E');
    final b = SystemSymbol.fromString('S-E');
    final c = SystemSymbol.fromString('S-Q');
    expect(a, b);
    expect(a, isNot(c));
    expect(a.sector, 'S');

    expect(() => SystemSymbol.fromString('S'), throwsFormatException);
    expect(() => SystemSymbol.fromString('S-E-A'), throwsFormatException);
  });
  test('WaypointSymbol equality', () {
    final a = WaypointSymbol.fromString('S-E-J');
    final b = WaypointSymbol.fromString('S-E-J');
    final c = WaypointSymbol.fromString('S-E-P');
    expect(a, b);
    expect(a, isNot(c));
    expect(a.sector, 'S');
    expect(a.system, SystemSymbol.fromString('S-E'));
    expect(a.systemString, 'S-E');

    expect(() => WaypointSymbol.fromString('S-E'), throwsFormatException);
    expect(() => WaypointSymbol.fromString('S-E-A-F'), throwsFormatException);
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
  test('WaypointSymbol.fromJsonOrNull', () {
    final symbol = WaypointSymbol.fromJsonOrNull('S-E-J');
    expect(symbol, WaypointSymbol.fromJsonOrNull('S-E-J'));
    expect(WaypointSymbol.fromJsonOrNull(null), isNull);

    // Invalid still throws.
    expect(() => WaypointSymbol.fromJsonOrNull('S-E'), throwsFormatException);
    expect(
      () => WaypointSymbol.fromJsonOrNull('S-E-A-F'),
      throwsFormatException,
    );
  });

  test('WaypointSymbol.waypointName and localSectorName', () {
    final symbol = WaypointSymbol.fromString('S-E-J');
    expect(symbol.waypointName, 'J');
    expect(symbol.sectorLocalName, 'E-J');
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

    // At least one hyphen is required.
    expect(() => ShipSymbol.fromString('A1'), throwsFormatException);
  });
}
