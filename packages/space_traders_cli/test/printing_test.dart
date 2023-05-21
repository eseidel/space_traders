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
}
