import 'package:space_traders_cli/api.dart';
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
      faction: WaypointFaction(symbol: FactionSymbols.AEGIS),
      traits: [
        WaypointTrait(
          description: 't',
          name: 'n',
          symbol: WaypointTraitSymbolEnum.CORRUPT,
        )
      ],
    );
    expect(waypointDescription(waypoint), 'a - PLANET - uncharted - n');
  });

  test('durationString', () {
    // I don't like that it always shows hours and minutes, even if they're 0.
    // But that's what we have for now, so testing it.
    expect(durationString(Duration.zero), '00:00:00');
    expect(durationString(const Duration(seconds: 1)), '00:00:01');
    expect(durationString(const Duration(seconds: 60)), '00:01:00');
    expect(durationString(const Duration(seconds: 3600)), '01:00:00');
  });

  test('contractDescription', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final contract = Contract(
      id: 'id',
      factionSymbol: 'faction',
      type: ContractTypeEnum.PROCUREMENT,
      terms: ContractTerms(
        deadline: moonLanding,
        payment: ContractPayment(onAccepted: 1000, onFulfilled: 1000),
        deliver: [],
      ),
      expiration: moonLanding,
      deadlineToAccept: moonLanding,
    );
    expect(
      contractDescription(contract),
      'PROCUREMENT from faction, deliver  by 1969-07-20 20:18:04.000 for '
      '1,000c with 1,000c upfront',
    );
  });
}
