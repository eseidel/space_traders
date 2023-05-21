import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/printing.dart';
import 'package:test/test.dart';

void main() {
  test('waypointDescription', () {
    final waypoint = Waypoint(
      symbol: 'a',
      type: WaypointType.PLANET,
      systemSymbol: 'c',
      x: 1,
      y: 2,
      orbitals: [],
      faction: WaypointFaction(symbol: 'f'),
      traits: [
        WaypointTrait(
          description: 't',
          name: 'n',
          symbol: WaypointTraitSymbolEnum.CORRUPT,
        )
      ],
    );
    expect(waypointDescription(waypoint), 'a - PLANET - n');
  });

  test('durationString', () {
    // I don't like that it always shows hours and minutes, even if they're 0.
    // But that's what we have for now, so testing it.
    expect(durationString(Duration.zero), '00:00:00');
    expect(durationString(const Duration(seconds: 1)), '00:00:01');
    expect(durationString(const Duration(seconds: 60)), '00:01:00');
    expect(durationString(const Duration(seconds: 3600)), '01:00:00');
  });
}
