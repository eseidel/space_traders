import 'package:test/test.dart';
import 'package:types/types.dart';

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
    expect(jumpGate.isType(WaypointType.PLANET), isFalse);
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
        ),
      ],
    );
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.ASH_CLOUDS), isTrue);
    expect(waypoint.hasTrait(WaypointTraitSymbolEnum.BARREN), isFalse);
    final systemWaypoint = waypoint.toSystemWaypoint();
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
  test('System distance', () {
    final a = System(
      symbol: 'S-A',
      sectorSymbol: 'S',
      type: SystemType.BLUE_STAR,
      x: 0,
      y: 0,
      waypoints: [],
    );
    final b = System(
      symbol: 'S-B',
      sectorSymbol: 'S',
      type: SystemType.BLUE_STAR,
      x: 10,
      y: 10,
      waypoints: [],
    );
    expect(a.distanceTo(b), 14);
    expect(b.distanceTo(a), 14);
    final aConnected = connectedSystemFromSystem(a, 0);
    final bConnected = connectedSystemFromSystem(b, 0);
    expect(aConnected.distanceTo(bConnected), 14);
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
  });

  test('FactionUtils', () {
    final faction = Faction(
      description: '',
      symbol: FactionSymbols.AEGIS,
      name: '',
      headquarters: 'S-A-W',
      traits: [],
      isRecruiting: true,
    );
    expect(faction.headquartersSymbol, WaypointSymbol.fromString('S-A-W'));
  });
  test('AgentUtils', () {
    final agent = Agent(
      symbol: 'A-1',
      headquarters: 'S-A-W',
      credits: 0,
      startingFaction: FactionSymbols.AEGIS.value,
    );
    expect(agent.headquartersSymbol, WaypointSymbol.fromString('S-A-W'));
  });
  test('tradeSymbolForMountSymbol', () {
    for (final mountSymbol in ShipMountSymbolEnum.values) {
      final tradeSymbol = tradeSymbolForMountSymbol(mountSymbol);
      expect(mountSymbolForTradeSymbol(tradeSymbol), mountSymbol);
    }
    // Non-mount symbols will fail however:
    expect(mountSymbolForTradeSymbol(TradeSymbol.ADVANCED_CIRCUITRY), isNull);
  });

  test('Market.allowsTradeOf', () {
    final market = Market(
      symbol: 'S-A-W',
      tradeGoods: [
        MarketTradeGood(
          symbol: 'FUEL',
          tradeVolume: 1,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
        ),
      ],
    );
    expect(market.allowsTradeOf(TradeSymbol.FABRICS), isFalse);
    expect(market.allowsTradeOf(TradeSymbol.FUEL), isTrue);
  });
}
