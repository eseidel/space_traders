import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:file/local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockWaypoint extends Mock implements Waypoint {}

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
        ),
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
  test('advanceMiner smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.system);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbolEnum.MINING_LASER_II,
        name: '',
        requirements: ShipRequirements(),
        strength: 10,
      ),
    ]);

    when(
      () => centralCommand.mineJobForShip(caches.systems, caches.agent, ship),
    ).thenReturn(MineJob(mine: symbol, market: symbol));

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID_FIELD);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => caches.ships.ships).thenReturn([ship]);

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = BehaviorState(shipSymbol, Behavior.miner);

    when(() => centralCommand.minimumSurveys).thenReturn(10);
    when(() => centralCommand.surveyPercentileThreshold).thenReturn(0.9);

    final cooldownAfterMining = Cooldown(
      shipSymbol: shipSymbol.symbol,
      remainingSeconds: 10,
      expiration: now.add(const Duration(seconds: 10)),
      totalSeconds: 21,
    );
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
            cooldown: cooldownAfterMining,
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
    registerFallbackValue(ExtractionRecord.fallbackValue());
    when(() => db.insertExtraction(any())).thenAnswer((_) => Future.value());

    final logger = _MockLogger();

    // With the reactor expiration, we should wait.
    final reactorExpiration = now.add(const Duration(seconds: 10));
    when(() => ship.cooldown).thenReturn(
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
        expiration: reactorExpiration,
      ),
    );
    final reactorWait = await runWithLogger(
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
    expect(reactorWait, reactorExpiration);

    // With no wait, we should be able to complete the mining.
    when(() => ship.cooldown).thenReturn(
      Cooldown(
        shipSymbol: shipSymbol.symbol,
        totalSeconds: 0,
        remainingSeconds: 0,
      ),
    );

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
    // Will wait after mining to mine again if cargo is not full.
    expect(waitUntil, cooldownAfterMining.expiration);
    verify(
      () => ship.cooldown = cooldownAfterMining,
    ).called(1);
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

  test('cooldownTimeForExtraction', () {
    final ship = _MockShip();
    final laser1 = ShipMount(
      symbol: ShipMountSymbolEnum.MINING_LASER_I,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(power: 1),
    );
    final laser2 = ShipMount(
      symbol: ShipMountSymbolEnum.MINING_LASER_II,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(power: 2),
    );
    when(() => ship.mounts).thenReturn([laser1, laser2]);
    expect(cooldownTimeForExtraction(ship), 90);
  });

  test('surveysExpectedPerSurveyWithMounts', () {
    final shipMounts = ShipMountCache.load(const LocalFileSystem());
    expect(
      surveysExpectedPerSurveyWithMounts(
        shipMounts,
        kSurveyOnlyTemplate.mounts,
      ),
      6,
    );
    expect(
      surveysExpectedPerSurveyWithMounts(
        shipMounts,
        kMineAndSurveyTemplate.mounts,
      ),
      1,
    );
  });
}
