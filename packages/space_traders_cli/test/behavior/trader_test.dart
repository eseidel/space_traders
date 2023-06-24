import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/trader.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorManager extends Mock implements BehaviorManager {}

class _MockDataStore extends Mock implements DataStore {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockPriceData extends Mock implements PriceData {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceContractTrader smoke test', () async {
    final api = _MockApi();
    final db = _MockDataStore();
    final priceData = _MockPriceData();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final behaviorManager = _MockBehaviorManager();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

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

    when(() => behaviorManager.getBehavior(ship)).thenAnswer(
      (_) => Future.value(BehaviorState(Behavior.arbitrageTrader)),
    );
    when(() => behaviorManager.disableBehavior(ship, Behavior.arbitrageTrader))
        .thenAnswer((_) => Future.value());

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
        db,
        priceData,
        agentCache,
        ship,
        systemsCache,
        waypointCache,
        marketCache,
        transactionLog,
        behaviorManager,
      ),
    );
    expect(waitUntil, isNull);
  });
}
