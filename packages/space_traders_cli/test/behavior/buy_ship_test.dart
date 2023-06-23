import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/buy_ship.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/ship_cache.dart';
import 'package:space_traders_cli/cache/shipyard_prices.dart';
import 'package:space_traders_cli/cache/surveys.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/cache/transactions.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class MockShipNav extends Mock implements ShipNav {}

class MockShipNavRoute extends Mock implements ShipNavRoute {}

class MockApi extends Mock implements Api {}

class MockDataStore extends Mock implements DataStore {}

class MockAgentCache extends Mock implements AgentCache {}

class MockShip extends Mock implements Ship {}

class MockSystemsCache extends Mock implements SystemsCache {}

class MockMarketCache extends Mock implements MarketCache {}

class MockTransactionLog extends Mock implements TransactionLog {}

class MockBehaviorManager extends Mock implements BehaviorManager {}

class MockPriceData extends Mock implements PriceData {}

class MockSurveyData extends Mock implements SurveyData {}

class MockWaypointCache extends Mock implements WaypointCache {}

class MockWaypoint extends Mock implements Waypoint {}

class MockLogger extends Mock implements Logger {}

class MockShipyardPrices extends Mock implements ShipyardPrices {}

class MockShipCache extends Mock implements ShipCache {}

void main() {
  // This test is nearly identical to minerBehavior in transit. This logic
  // should be moved to a shared place and tested once.
  test('advanceBuyShip in transit', () async {
    final api = MockApi();
    final db = MockDataStore();
    final priceData = MockPriceData();
    final agentCache = MockAgentCache();
    final ship = MockShip();
    final systemsCache = MockSystemsCache();
    final waypointCache = MockWaypointCache();
    final marketCache = MockMarketCache();
    final transactionLog = MockTransactionLog();
    final behaviorManager = MockBehaviorManager();
    final shipNav = MockShipNav();
    final shipNavRoute = MockShipNavRoute();
    final shipyardPrices = MockShipyardPrices();
    final shipCache = MockShipCache();

    final now = DateTime(2021);
    final arrivalTime = now.add(const Duration(seconds: 1));
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    when(() => shipNav.waypointSymbol).thenReturn('W');
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNavRoute.arrival).thenReturn(arrivalTime);

    final logger = MockLogger();
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
    expect(waitUntil, arrivalTime);
    verify(() => logger.info('🛸#S  ✈️  to W, 00:00:01 left')).called(1);
  });
}
