import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/behavior/behavior.dart';
import 'package:space_traders_cli/behavior/central_command.dart';
import 'package:space_traders_cli/behavior/miner.dart';
import 'package:space_traders_cli/cache/caches.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:test/test.dart';

class _MockShipNav extends Mock implements ShipNav {}

class _MockApi extends Mock implements Api {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockShip extends Mock implements Ship {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockPriceData extends Mock implements MarketPrices {}

class _MockSurveyData extends Mock implements SurveyData {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockLogger extends Mock implements Logger {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockCaches extends Mock implements Caches {}

void main() {
  test('surveyWorthMining with no surveys', () async {
    final marketPrices = _MockPriceData();
    final surveyData = _MockSurveyData();
    when(
      () => surveyData.recentSurveysAtWaypoint(
        count: any(named: 'count'),
        waypointSymbol: any(named: 'waypointSymbol'),
      ),
    ).thenReturn([]);
    final maybeSurvey = await surveyWorthMining(
      marketPrices,
      surveyData,
      surveyWaypointSymbol: 'S-E-A',
      nearbyMarketSymbol: 'S-E-A',
    );
    expect(maybeSurvey, isNull);
  });

  test('surveyWorthMining', () async {
    final marketPrices = _MockPriceData();
    final surveyData = _MockSurveyData();
    final now = DateTime(2021);
    DateTime getNow() => now;
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
      () => marketPrices.recentSellPrice(
        marketSymbol: any(named: 'marketSymbol'),
        tradeSymbol: 'DIAMONDS',
      ),
    ).thenReturn(100);
    when(
      () => marketPrices.recentSellPrice(
        marketSymbol: any(named: 'marketSymbol'),
        tradeSymbol: 'ALUMINUM',
      ),
    ).thenReturn(10);
    final maybeSurvey = await surveyWorthMining(
      marketPrices,
      surveyData,
      surveyWaypointSymbol: 'S-E-A',
      nearbyMarketSymbol: 'S-E-A',
      getNow: getNow,
    );
    expect(maybeSurvey!.deposits.first.symbol, 'DIAMONDS');
  });
  test('nearestWaypointWithMarket returns start', () async {
    final waypointCache = _MockWaypointCache();
    final start = _MockWaypoint();
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
    final waypointCache = _MockWaypointCache();
    final start = _MockWaypoint();
    final market = _MockWaypoint();
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
    final waypointCache = _MockWaypointCache();
    final start = _MockWaypoint();
    final market = _MockWaypoint();
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

  test('advanceMiner smoke test', () async {
    final api = _MockApi();
    final marketPrices = _MockPriceData();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final surveyData = _MockSurveyData();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.surveys).thenReturn(surveyData);

    final now = DateTime(2021);
    DateTime getNow() => now;
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.systemSymbol).thenReturn('S-A');

    final waypoint = _MockWaypoint();
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.systemSymbol).thenReturn('S-A');

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => waypointCache.waypointsInJumpRadius(
        startSystem: any(named: 'startSystem'),
        maxJumps: any(named: 'maxJumps'),
      ),
    ).thenAnswer((_) => Stream.fromIterable([waypoint]));

    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: any(named: 'startSystem'),
        maxJumps: any(named: 'maxJumps'),
      ),
    ).thenAnswer((_) => Stream.fromIterable([('S-A', 0)]));

    when(
      () => waypointCache.waypointsInSystem(any()),
    ).thenAnswer((_) => Future.value([waypoint]));

    when(() => marketCache.marketsInSystem(any()))
        .thenAnswer((_) => Stream.fromIterable([]));

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);

    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehavior(ship, Behavior.miner, any(), any()),
    ).thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceMiner(
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
