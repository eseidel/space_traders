import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/explorer.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockShipNav extends Mock implements ShipNav {}

class _MockApi extends Mock implements Api {}

class _MockDataStore extends Mock implements DataStore {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockShip extends Mock implements Ship {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockBehaviorManager extends Mock implements BehaviorManager {}

class _MockPriceData extends Mock implements PriceData {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockLogger extends Mock implements Logger {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockFleetApi extends Mock implements FleetApi {}

void main() {
  test('advanceExplorer smoke test', () async {
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
    final shipyardPrices = _MockShipyardPrices();
    final fleetApi = _MockFleetApi();

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);

    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.createChart(any())).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(chart: Chart(), waypoint: waypoint),
        ),
      ),
    );

    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('W');

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => behaviorManager.completeBehavior(any()))
        .thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceExplorer(
        api,
        db,
        transactionLog,
        priceData,
        shipyardPrices,
        agentCache,
        ship,
        systemsCache,
        waypointCache,
        marketCache,
        behaviorManager,
      ),
    );
    expect(waitUntil, isNull);
  });
}
