import 'package:cli/behavior/buy_ship.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceBuyShip smoke test', () async {
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
    final shipCache = _MockShipCache();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.ships).thenReturn(shipCache);

    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);

    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => agentCache.headquartersSymbol).thenReturn(symbol);
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);

    final waypoint = _MockWaypoint();
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.SHIPYARD,
        name: '',
        description: '',
      )
    ]);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(() => waypointCache.shipyardWaypointsForSystem(symbol.systemSymbol))
        .thenAnswer((_) => Future.value([waypoint]));
    when(() => waypointCache.waypointsInSystem(symbol.systemSymbol))
        .thenAnswer((_) => Future.value([waypoint]));
    when(() => shipCache.ships).thenReturn([ship]);
    when(() => shipCache.frameCounts).thenReturn({});

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceBuyShip(
        api,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, isNull);
  });
}
