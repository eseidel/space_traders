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

  test('shipDescription', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final ship = Ship(
      symbol: 'A',
      registration: ShipRegistration(
        factionSymbol: FactionSymbols.AEGIS.value,
        name: 'name',
        role: ShipRole.COMMAND,
      ),
      nav: ShipNav(
        systemSymbol: 'c',
        waypointSymbol: 'symbol',
        route: ShipNavRoute(
          destination: ShipNavRouteWaypoint(
            symbol: 'a',
            type: WaypointType.PLANET,
            systemSymbol: 'c',
            x: 1,
            y: 2,
          ),
          departure: ShipNavRouteWaypoint(
            symbol: 'a',
            type: WaypointType.PLANET,
            systemSymbol: 'c',
            x: 1,
            y: 2,
          ),
          arrival: moonLanding,
          departureTime: moonLanding,
        ),
        status: ShipNavStatus.DOCKED,
        flightMode: ShipNavFlightMode.CRUISE,
      ),
      crew: ShipCrew(
        current: 0,
        required_: 0,
        capacity: 0,
        morale: 90,
        wages: 0,
      ),
      frame: ShipFrame(
        symbol: ShipFrameSymbolEnum.CARRIER,
        name: 'name',
        description: 'description',
        condition: 90,
        moduleSlots: 0,
        mountingPoints: 0,
        fuelCapacity: 0,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
      reactor: ShipReactor(
        symbol: ShipReactorSymbolEnum.FISSION_I,
        name: 'name',
        description: 'description',
        condition: 90,
        powerOutput: 100,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
      engine: ShipEngine(
        symbol: ShipEngineSymbolEnum.ION_DRIVE_I,
        name: 'name',
        description: 'description',
        condition: 90,
        speed: 100,
        requirements: ShipRequirements(crew: 0, power: 0, slots: 0),
      ),
      cargo: ShipCargo(
        capacity: 100,
        units: 100,
        inventory: [],
      ),
      fuel: ShipFuel(
        current: 100,
        capacity: 100,
      ),
    );
    final shipWaypoints = [
      Waypoint(
        symbol: 'symbol',
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
      ),
    ];
    expect(
      shipDescription(ship, shipWaypoints),
      'A - Docked at symbol PLANET COMMAND 100/100 (morale: 90) (condition: 90)',
    );
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

  test('approximateDuration', () {
    expect(approximateDuration(Duration.zero), '0s');
    expect(approximateDuration(const Duration(seconds: 1)), '1s');
    expect(approximateDuration(const Duration(seconds: 60)), '1m');
    expect(approximateDuration(const Duration(seconds: 3600)), '1h');
    expect(approximateDuration(const Duration(seconds: 3600 * 24)), '1d');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 7)), '7d');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 30)), '30d');
    expect(
      approximateDuration(const Duration(seconds: 3600 * 24 * 365)),
      '365d',
    );
  });

  test('cargoDescription', () {
    final cargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [
        ShipCargoItem(symbol: 'A', name: 'name', description: '', units: 1),
        ShipCargoItem(symbol: 'B', name: 'name2', description: '', units: 2),
      ],
    );
    expect(cargoDescription(cargo), '1 name, 2 name2');
  });
}
