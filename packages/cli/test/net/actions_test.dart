import 'package:cli/api.dart';
import 'package:cli/cache/agent_cache.dart';
import 'package:cli/cache/ship_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockApi extends Mock implements Api {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardTransaction extends Mock implements ShipyardTransaction {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipFuel extends Mock implements ShipFuel {}

void main() {
  test('purchaseShip', () async {
    final Api api = _MockApi();
    final FleetApi fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final shipCache = _MockShipCache();
    final agent1 = _MockAgent();
    final agent2 = _MockAgent();
    when(agent2.toJson).thenReturn({});

    final responseData = PurchaseShip201ResponseData(
      agent: agent2,
      ship: _MockShip(),
      transaction: _MockShipyardTransaction(),
    );

    when(
      () => fleetApi.purchaseShip(
        purchaseShipRequest: any(named: 'purchaseShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(PurchaseShip201Response(data: responseData)),
    );

    when(() => shipCache.updateShip(responseData.ship)).thenAnswer(
      (invocation) => Future.value(),
    );

    final fs = MemoryFileSystem.test();
    final agentCache = AgentCache(agent1, fs: fs);
    const shipyardSymbol = 'SY';
    const shipType = ShipType.PROBE;
    await purchaseShip(
      api,
      shipCache,
      agentCache,
      shipyardSymbol,
      shipType,
    );
    verify(
      () => shipCache.updateShip(responseData.ship),
    ).called(1);
    expect(agentCache.agent, agent2);
  });

  test('setShipFlightMode', () async {
    final Api api = _MockApi();
    final FleetApi fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipNav = _MockShipNav();
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('SY');
    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(GetShipNav200Response(data: shipNav)),
    );

    await setShipFlightMode(api, ship, ShipNavFlightMode.CRUISE);
    verify(() => ship.nav = shipNav).called(1);
  });

  test('undockIfNeeded', () async {
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.orbitShip(any())).thenAnswer(
      (invocation) => Future.value(
        OrbitShip200Response(
          data: OrbitShip200ResponseData(nav: _MockShipNav()),
        ),
      ),
    );
    final ship = _MockShip();
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('A');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final logger = _MockLogger();
    await runWithLogger(logger, () => undockIfNeeded(api, ship));
    verifyNever(() => fleetApi.orbitShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    await runWithLogger(logger, () => undockIfNeeded(api, ship));
    verify(() => fleetApi.orbitShip(any())).called(1);
  });

  test('dockIfNeeded', () async {
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.dockShip(any())).thenAnswer(
      (invocation) => Future.value(
        DockShip200Response(
          data: OrbitShip200ResponseData(nav: _MockShipNav()),
        ),
      ),
    );
    final ship = _MockShip();
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('A');
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final logger = _MockLogger();
    await runWithLogger(logger, () => dockIfNeeded(api, ship));
    verifyNever(() => fleetApi.dockShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    await runWithLogger(logger, () => dockIfNeeded(api, ship));
    verify(() => fleetApi.dockShip(any())).called(1);
  });

  test('navigateToLocalWaypoint sets probes to burn', () async {
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('A');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    final shipFuel = _MockShipFuel();
    when(() => ship.fuel).thenReturn(shipFuel);
    when(() => shipFuel.capacity).thenReturn(0);

    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        GetShipNav200Response(data: _MockShipNav()),
      ),
    );

    when(
      () => fleetApi.navigateShip(
        any(),
        navigateShipRequest: any(named: 'navigateShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        NavigateShip200Response(
          data: NavigateShip200ResponseData(
            fuel: shipFuel,
            nav: _MockShipNav(),
          ),
        ),
      ),
    );

    final logger = _MockLogger();
    await runWithLogger(logger, () => navigateToLocalWaypoint(api, ship, 'B'));

    verify(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest:
            PatchShipNavRequest(flightMode: ShipNavFlightMode.BURN),
      ),
    ).called(1);
  });
}
