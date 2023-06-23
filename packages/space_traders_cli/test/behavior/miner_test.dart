import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/cache/agent_cache.dart';
import 'package:space_traders_cli/cache/data_store.dart';
import 'package:space_traders_cli/cache/prices.dart';
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

void main() {
  test('surveyWorthMining with no surveys', () async {
    final priceData = MockPriceData();
    final surveyData = MockSurveyData();
    when(
      () => surveyData.recentSurveysAtWaypoint(
        count: any(named: 'count'),
        waypointSymbol: any(named: 'waypointSymbol'),
      ),
    ).thenReturn([]);
    final maybeSurvey = await surveyWorthMining(
      priceData,
      surveyData,
      surveyWaypointSymbol: 'S-E-A',
      nearbyMarketSymbol: 'S-E-A',
    );
    expect(maybeSurvey, isNull);
  });

  test('surveyWorthMining', () async {
    final priceData = MockPriceData();
    final surveyData = MockSurveyData();
    final now = DateTime.timestamp();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    final surveys = [
      for (int i = 0; i < 10; i++)
        HistoricalSurvey(
          timestamp: now.subtract(Duration(seconds: i)),
          exhausted: false,
          survey: Survey(
            expiration: oneHourFromNow,
            signature: 'sig$i',
            symbol: 'sym',
            deposits: [
              SurveyDeposit(
                symbol: (i == 0) ? 'DIAMONDS' : 'ALUMINUM',
              ),
            ],
            size: SurveySizeEnum.SMALL,
          ),
        )
    ];
    when(
      () => surveyData.recentSurveysAtWaypoint(
        count: any(named: 'count'),
        waypointSymbol: any(named: 'waypointSymbol'),
      ),
    ).thenReturn(surveys);
    when(
      () => priceData.recentSellPrice(
        marketSymbol: any(named: 'marketSymbol'),
        tradeSymbol: 'DIAMONDS',
      ),
    ).thenReturn(100);
    when(
      () => priceData.recentSellPrice(
        marketSymbol: any(named: 'marketSymbol'),
        tradeSymbol: 'ALUMINUM',
      ),
    ).thenReturn(10);
    final maybeSurvey = await surveyWorthMining(
      priceData,
      surveyData,
      surveyWaypointSymbol: 'S-E-A',
      nearbyMarketSymbol: 'S-E-A',
    );
    expect(maybeSurvey!.deposits.first.symbol, 'DIAMONDS');
  });
  test('nearestWaypointWithMarket returns start', () async {
    final waypointCache = MockWaypointCache();
    final start = MockWaypoint();
    when(() => start.traits).thenReturn(
      [
        WaypointTrait(
          symbol: WaypointTraitSymbolEnum.MARKETPLACE,
          name: '',
          description: '',
        )
      ],
    );
    final nearest = await nearestWaypointWithMarket(waypointCache, start);
    expect(nearest, start);
  });

  test('nearestWaypointWithMarket null', () async {
    final waypointCache = MockWaypointCache();
    final start = MockWaypoint();
    final market = MockWaypoint();
    when(() => start.traits).thenReturn([]);
    when(() => start.systemSymbol).thenReturn('S-E');
    when(
      () => waypointCache.waypointsInJumpRadius(
        startSystem: any(named: 'startSystem'),
        maxJumps: any(named: 'maxJumps'),
      ),
    ).thenAnswer((_) => Stream.fromIterable([market]));
    when(() => market.traits).thenReturn([]);
    final nearest = await nearestWaypointWithMarket(waypointCache, start);
    expect(nearest, isNull);
  });

  test('nearestWaypointWithMarket', () async {
    final waypointCache = MockWaypointCache();
    final start = MockWaypoint();
    final market = MockWaypoint();
    when(() => start.traits).thenReturn([]);
    when(() => start.systemSymbol).thenReturn('S-E');
    when(
      () => waypointCache.waypointsInJumpRadius(
        startSystem: any(named: 'startSystem'),
        maxJumps: any(named: 'maxJumps'),
      ),
    ).thenAnswer((_) => Stream.fromIterable([market]));
    when(() => market.traits).thenReturn(
      [
        WaypointTrait(
          symbol: WaypointTraitSymbolEnum.MARKETPLACE,
          name: '',
          description: '',
        )
      ],
    );
    final nearest = await nearestWaypointWithMarket(waypointCache, start);
    expect(nearest, market);
  });

  // This is mostly a proof of concept that we can test advance* functions.
  test('advanceMiner in transit', () async {
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
    final surveyData = MockSurveyData();
    final shipNav = MockShipNav();
    final shipNavRoute = MockShipNavRoute();

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
      () => advanceMiner(
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
        surveyData,
        getNow: getNow,
      ),
    );
    expect(waitUntil, arrivalTime);
    verify(() => logger.info('🛸#S  ✈️  to W, 00:00:01 left')).called(1);
  });
}
