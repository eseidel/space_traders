import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
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

class _MockSurveyData extends Mock implements SurveyData {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockLogger extends Mock implements Logger {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockCaches extends Mock implements Caches {}

void main() {
  test('surveyWorthMining with no surveys', () async {
    final marketPrices = _MockMarketPrices();
    final surveyData = _MockSurveyData();
    final symbol = WaypointSymbol.fromString('S-E-A');
    when(
      () => surveyData.recentSurveysAtWaypoint(
        symbol,
        count: any(named: 'count'),
      ),
    ).thenReturn([]);
    final maybeSurvey = await surveyWorthMining(
      marketPrices,
      surveyData,
      surveyWaypointSymbol: symbol,
      nearbyMarketSymbol: symbol,
    );
    expect(maybeSurvey, isNull);
  });

  test('surveyWorthMining', () async {
    final marketPrices = _MockMarketPrices();
    final surveyData = _MockSurveyData();
    final now = DateTime(2021);
    DateTime getNow() => now;
    final oneHourFromNow = now.add(const Duration(hours: 1));
    final waypointSymbol = WaypointSymbol.fromString('S-E-A');
    final surveys = [
      for (int i = 0; i < 10; i++)
        HistoricalSurvey(
          timestamp: now.subtract(Duration(seconds: i)),
          exhausted: false,
          survey: Survey(
            expiration: oneHourFromNow,
            signature: 'sig$i',
            symbol: waypointSymbol.waypoint,
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
        waypointSymbol,
        count: any(named: 'count'),
      ),
    ).thenReturn(surveys);
    when(
      () => marketPrices.recentSellPrice(
        TradeSymbol.DIAMONDS,
        marketSymbol: waypointSymbol,
      ),
    ).thenReturn(100);
    when(
      () => marketPrices.recentSellPrice(
        TradeSymbol.ALUMINUM,
        marketSymbol: waypointSymbol,
      ),
    ).thenReturn(10);
    final maybeSurvey = await surveyWorthMining(
      marketPrices,
      surveyData,
      surveyWaypointSymbol: waypointSymbol,
      nearbyMarketSymbol: waypointSymbol,
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
    final symbol = WaypointSymbol.fromString('S-E-W');
    when(() => start.symbol).thenReturn(symbol.waypoint);
    when(() => start.systemSymbol).thenReturn(symbol.system);
    when(
      () => waypointCache.waypointsInJumpRadius(
        startSystem: symbol.systemSymbol,
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
    final symbol = WaypointSymbol.fromString('S-E-W');
    when(() => start.symbol).thenReturn(symbol.waypoint);
    when(() => start.systemSymbol).thenReturn(symbol.system);
    when(
      () => waypointCache.waypointsInJumpRadius(
        startSystem: symbol.systemSymbol,
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
    final marketPrices = _MockMarketPrices();
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
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);

    final waypoint = _MockWaypoint();
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    registerFallbackValue(symbol.systemSymbol);
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
    ).thenReturn([(symbol.systemSymbol, 0)]);

    when(
      () => waypointCache.waypointsInSystem(any()),
    ).thenAnswer((_) => Future.value([waypoint]));

    when(() => marketCache.marketsInSystem(any()))
        .thenAnswer((_) => Stream.fromIterable([]));

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);

    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehaviorForShip(
        ship,
        Behavior.miner,
        any(),
        any(),
      ),
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
