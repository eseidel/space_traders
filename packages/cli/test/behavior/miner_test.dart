import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockBehaviorState extends Mock implements BehaviorState {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockExtractionLog extends Mock implements ExtractionLog {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('surveyWorthMining with no surveys', () async {
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final symbol = WaypointSymbol.fromString('S-E-A');
    when(() => db.recentSurveysAtWaypoint(symbol, count: 100))
        .thenAnswer((_) => Future.value([]));
    final maybeSurvey = await surveyWorthMining(
      db,
      marketPrices,
      surveyWaypointSymbol: symbol,
      nearbyMarketSymbol: symbol,
    );
    expect(maybeSurvey, isNull);
  });

  test('surveyWorthMining', () async {
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
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
    when(() => db.recentSurveysAtWaypoint(waypointSymbol, count: 100))
        .thenAnswer((_) => Future.value(surveys));
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
      db,
      marketPrices,
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
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    final extractionLog = _MockExtractionLog();
    when(() => caches.extractions).thenReturn(extractionLog);

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);
    when(() => ship.mounts).thenReturn([]);

    when(() => centralCommand.mineJobForShip(systemsCache, agentCache, ship))
        .thenReturn(MineJob(mine: symbol, market: symbol));

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    final shipCache = _MockShipCache();
    when(() => shipCache.ships).thenReturn([ship]);
    when(() => caches.ships).thenReturn(shipCache);

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = _MockBehaviorState();

    when(() => centralCommand.minimumSurveys).thenReturn(10);
    when(() => centralCommand.surveyPercentileThreshold).thenReturn(0.9);

    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.extractResources(
        shipSymbol.symbol,
      ),
    ).thenAnswer(
      (_) => Future.value(
        ExtractResources201Response(
          data: ExtractResources201ResponseData(
            cooldown: Cooldown(
              shipSymbol: shipSymbol.symbol,
              remainingSeconds: 0,
              expiration: now,
              totalSeconds: 0,
            ),
            extraction: Extraction(
              shipSymbol: shipSymbol.symbol,
              yield_: ExtractionYield(
                symbol: TradeSymbol.DIAMONDS,
                units: 10,
              ),
            ),
            cargo: shipCargo,
          ),
        ),
      ),
    );
    when(() => db.recentSurveysAtWaypoint(symbol, count: 100))
        .thenAnswer((_) => Future.value([]));

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceMiner(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: getNow,
      ),
    );
    expect(waitUntil, DateTime(2021));
  });

  test('maxExtractedUnits', () {
    final ship = _MockShip();
    when(() => ship.cargo).thenReturn(ShipCargo(capacity: 60, units: 0));
    final laser1 = ShipMount(
      symbol: ShipMountSymbolEnum.MINING_LASER_I,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(),
    );
    final laser2 = ShipMount(
      symbol: ShipMountSymbolEnum.MINING_LASER_II,
      name: '',
      description: '',
      strength: 25,
      requirements: ShipRequirements(),
    );
    final laser3 = ShipMount(
      symbol: ShipMountSymbolEnum.MINING_LASER_III,
      name: '',
      description: '',
      strength: 60,
      requirements: ShipRequirements(),
    );

    when(() => ship.mounts).thenReturn([laser1]);
    expect(maxExtractedUnits(ship), 15);
    when(() => ship.mounts).thenReturn([laser1, laser1]);
    expect(maxExtractedUnits(ship), 30);
    when(() => ship.mounts).thenReturn([laser1, laser2]);
    expect(maxExtractedUnits(ship), 45);
    // Limited by cargo capacity
    when(() => ship.mounts).thenReturn([laser1, laser2, laser3]);
    expect(maxExtractedUnits(ship), 60);
    when(() => ship.cargo).thenReturn(ShipCargo(capacity: 120, units: 0));
    expect(maxExtractedUnits(ship), 110);
  });
}
