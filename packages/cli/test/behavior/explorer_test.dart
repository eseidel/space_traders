import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/explorer.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockShipNav extends Mock implements ShipNav {}

class _MockApi extends Mock implements Api {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockShip extends Mock implements Ship {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockLogger extends Mock implements Logger {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockCaches extends Mock implements Caches {}

class _MockChartingCache extends Mock implements ChartingCache {}

void main() {
  test('advanceExplorer smoke test', () async {
    final api = _MockApi();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipNav = _MockShipNav();
    final shipyardPrices = _MockShipyardPrices();
    final fleetApi = _MockFleetApi();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    final chartingCache = _MockChartingCache();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.charting).thenReturn(chartingCache);

    final waypoint = _MockWaypoint();
    final waypointSymbol = WaypointSymbol.fromString('S-A-B');
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

    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');

    registerFallbackValue(waypointSymbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(
      () => centralCommand.visitLocalShipyard(
        api,
        shipyardPrices,
        agentCache,
        waypoint,
        ship,
      ),
    ).thenAnswer((_) => Future.value());
    when(() => centralCommand.maxAgeForExplorerData)
        .thenReturn(const Duration(days: 3));

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceExplorer(
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
