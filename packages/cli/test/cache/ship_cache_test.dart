import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockApi extends Mock implements Api {}

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

void main() {
  test('frameCounts', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final fs = MemoryFileSystem.test();
    final shipCache = ShipCache([one, two, three], fs: fs);
    expect(
      shipCache.frameCounts,
      {ShipFrameSymbolEnum.MINER: 2, ShipFrameSymbolEnum.FIGHTER: 1},
    );

    expect(shipCache.countOfFrame(ShipFrameSymbolEnum.MINER), 2);
  });

  test('describeFleet', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final two = _MockShip();
    final twoFrame = _MockShipFrame();
    when(() => two.frame).thenReturn(twoFrame);
    when(() => twoFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final three = _MockShip();
    final threeFrame = _MockShipFrame();
    when(() => three.frame).thenReturn(threeFrame);
    when(() => threeFrame.symbol).thenReturn(ShipFrameSymbolEnum.FIGHTER);
    final four = _MockShip();
    final fourFrame = _MockShipFrame();
    when(() => four.frame).thenReturn(fourFrame);
    when(() => fourFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);
    final fs = MemoryFileSystem.test();
    final shipCache = ShipCache([one, two, three, four], fs: fs);
    expect(
      describeFleet(shipCache),
      'Fleet: 2 Carrier, 1 Fighter, 1 Light Freighter',
    );
  });

  test('describeFleet empty', () {
    final fs = MemoryFileSystem.test();
    final shipCache = ShipCache([], fs: fs);
    expect(describeFleet(shipCache), 'Fleet: 0 ships');
  });

  test('describeFleet one', () {
    final one = _MockShip();
    final oneFrame = _MockShipFrame();
    when(() => one.frame).thenReturn(oneFrame);
    when(() => oneFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final fs = MemoryFileSystem.test();
    final shipCache = ShipCache([one], fs: fs);
    expect(describeFleet(shipCache), 'Fleet: 1 Carrier');
  });

  test('ShipCache load save', () async {
    final api = _MockApi();
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final fs = MemoryFileSystem.test();
    final origin = ShipNavRouteWaypoint(
      symbol: 'a',
      type: WaypointType.PLANET,
      systemSymbol: 'c',
      x: 1,
      y: 2,
    );
    const shipSymbol = ShipSymbol('A', 1);
    final ship = Ship(
      symbol: shipSymbol.symbol,
      registration: ShipRegistration(
        factionSymbol: FactionSymbols.AEGIS.value,
        name: 'name',
        role: ShipRole.COMMAND,
      ),
      cooldown: Cooldown(
        shipSymbol: shipSymbol.symbol,
        remainingSeconds: 0,
        totalSeconds: 0,
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
          origin: origin,
          departure: origin,
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
    final ships = [ship];
    ShipCache(ships, fs: fs).save();
    final shipCache2 = await ShipCache.load(api, fs: fs);
    expect(shipCache2.ships.length, ships.length);
    // Ship.toJson doesn't recurse (openapi gen bug), so use jsonEncode.
    expect(jsonEncode(shipCache2.ships.first), jsonEncode(ship));

    expect(shipCache2.shipSymbols, [shipSymbol]);
    expect(shipCache2.ship(shipSymbol).shipSymbol, shipSymbol);
  });
}
