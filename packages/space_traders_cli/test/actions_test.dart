import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/net/actions.dart';
import 'package:test/test.dart';

class MockApi extends Mock implements Api {}

class MockFleetApi extends Mock implements FleetApi {}

class MockAgent extends Mock implements Agent {}

class MockShip extends Mock implements Ship {}

class MockShipyardTransaction extends Mock implements ShipyardTransaction {}

class MockShipNav extends Mock implements ShipNav {}

void main() {
  test('purchaseShip', () async {
    final Api api = MockApi();
    final FleetApi fleetApi = MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final shipCache = ShipCache([]);
    final agent1 = MockAgent();
    final agent2 = MockAgent();

    final responseData = PurchaseShip201ResponseData(
      agent: agent2,
      ship: MockShip(),
      transaction: MockShipyardTransaction(),
    );

    when(
      () => fleetApi.purchaseShip(
        purchaseShipRequest: any(named: 'purchaseShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(PurchaseShip201Response(data: responseData)),
    );

    final agentCache = AgentCache(agent1);
    const shipyardSymbol = 'SY';
    const shipType = ShipType.PROBE;
    await purchaseShip(
      api,
      shipCache,
      agentCache,
      shipyardSymbol,
      shipType,
    );
    expect(shipCache.ships, hasLength(1));
    expect(agentCache.agent, agent2);
  });

  test('setShipFlightMode', () async {
    final Api api = MockApi();
    final FleetApi fleetApi = MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipNav = MockShipNav();
    final ship = MockShip();
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
}