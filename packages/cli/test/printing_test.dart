import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/printing.dart';
import 'package:file/memory.dart';
import 'package:mason_logger/mason_logger.dart';
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
        deliver: [
          ContractDeliverGood(
            tradeSymbol: 'T',
            destinationSymbol: 'W',
            unitsFulfilled: 0,
            unitsRequired: 10,
          )
        ],
      ),
      expiration: moonLanding,
      deadlineToAccept: moonLanding,
    );
    final localTime = moonLanding.toLocal().toString();
    expect(
      contractDescription(contract),
      'PROCUREMENT from faction, deliver 10 T to W by $localTime for '
      '1,000c with 1,000c upfront',
    );
  });

  test('stringForPriceDeviance', () {
    final fs = MemoryFileSystem.test();
    final marketPrices = MarketPrices([], fs: fs);
    expect(
      stringForPriceDeviance(
        marketPrices,
        'A',
        0,
        MarketTransactionTypeEnum.PURCHASE,
      ),
      '            🤷',
    );
    marketPrices.addPrices([
      MarketPrice(
        waypointSymbol: 'A',
        symbol: 'A',
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 1,
        sellPrice: 2,
        tradeVolume: 100,
        timestamp: DateTime.timestamp(),
      )
    ]);

    expect(
      stringForPriceDeviance(
        marketPrices,
        'A',
        0,
        MarketTransactionTypeEnum.PURCHASE,
      ),
      lightGreen.wrap('-100%  -1c per'),
    );
    expect(
      stringForPriceDeviance(
        marketPrices,
        'A',
        0,
        MarketTransactionTypeEnum.SELL,
      ),
      lightRed.wrap('-100%  -2c per'),
    );
    expect(
      stringForPriceDeviance(
        marketPrices,
        'A',
        2,
        MarketTransactionTypeEnum.SELL,
      ),
      '            ⚖️ ',
    );
  });

  test('approximateDuration', () {
    expect(approximateDuration(Duration.zero), '0ms');
    expect(approximateDuration(const Duration(microseconds: 1)), '0ms');
    expect(approximateDuration(const Duration(milliseconds: 1)), '1ms');
    expect(approximateDuration(const Duration(seconds: 1)), '1s');
    expect(approximateDuration(const Duration(seconds: 60)), '1m');
    expect(approximateDuration(const Duration(seconds: 3600)), '1h');
    expect(approximateDuration(const Duration(seconds: 3600 * 24)), '1d');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 7)), '1w');
    expect(approximateDuration(const Duration(seconds: 3600 * 24 * 30)), '4w');
    expect(
      approximateDuration(const Duration(seconds: 3600 * 24 * 365)),
      '1y',
    );
    expect(
      approximateDuration(const Duration(seconds: 3600 * 24 * 365 * 3)),
      '3y',
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
