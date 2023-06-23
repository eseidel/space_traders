import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/buy_ship.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
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

class _MockShipCache extends Mock implements ShipCache {}

void main() {
  test('advanceBuyShip smoke test', () async {
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
    final shipCache = _MockShipCache();

    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('W');

    final waypoint = _MockWaypoint();
    when(() => waypoint.systemSymbol).thenReturn('S-A');

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => shipCache.frameCounts).thenReturn({});

    when(() => behaviorManager.disableBehavior(ship, Behavior.buyShip))
        .thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceBuyShip(
        api,
        db,
        priceData,
        shipyardPrices,
        agentCache,
        shipCache,
        ship,
        systemsCache,
        waypointCache,
        marketCache,
        transactionLog,
        behaviorManager,
        getNow: getNow,
      ),
    );
    expect(waitUntil, isNull);
  });
}
