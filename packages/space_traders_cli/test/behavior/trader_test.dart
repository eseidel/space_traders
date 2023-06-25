import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockPriceData extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceContractTrader smoke test', () async {
    final api = _MockApi();
    final marketPrices = _MockPriceData();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipyardPrices = _MockShipyardPrices();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);

    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-B');
    when(() => shipNav.systemSymbol).thenReturn('S-A');

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenAnswer((invocation) => Stream.fromIterable([]));

    when(() => centralCommand.getBehavior('S')).thenAnswer(
      (_) => BehaviorState('S', Behavior.arbitrageTrader),
    );
    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehavior(
        ship,
        Behavior.arbitrageTrader,
        any(),
        any(),
      ),
    ).thenAnswer((_) => Future.value());

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceArbitrageTrader(
        api,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(waitUntil, isNull);
  });
}
