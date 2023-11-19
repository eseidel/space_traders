import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/mining.dart';
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

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockWaypoint extends Mock implements Waypoint {}

void main() {
  test('surveyWorthMining with no surveys', () async {
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final symbol = WaypointSymbol.fromString('S-E-A');
    when(() => db.recentSurveysAtWaypoint(symbol, count: 100))
        .thenAnswer((_) => Future.value([]));
    final surveys = await surveysWorthMining(
      db,
      marketPrices,
      surveyWaypointSymbol: symbol,
      nearbyMarketSymbol: symbol,
    );
    expect(surveys, isEmpty);
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
    final worthMining = await surveysWorthMining(
      db,
      marketPrices,
      surveyWaypointSymbol: waypointSymbol,
      nearbyMarketSymbol: waypointSymbol,
      getNow: getNow,
    );
    expect(worthMining.first.survey.deposits.first.symbol, 'DIAMONDS');
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

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(symbol.waypoint);
    when(() => waypoint.type).thenReturn(WaypointType.ASTEROID);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbol.COMMON_METAL_DEPOSITS,
        name: 'name',
        description: 'description',
      ),
    ]);
    when(() => waypoint.systemSymbol).thenReturn(symbol.system);

    registerFallbackValue(symbol);
    when(() => caches.waypoints.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => caches.ships.ships).thenReturn([ship]);

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..mineJob = MineJob(mine: symbol, market: symbol);

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

  test('travelAndSellCargo smoke test', () async {
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
    const tradeSymbol = TradeSymbol.DIAMONDS;
    final shipCargo = ShipCargo(
      capacity: 60,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: tradeSymbol,
          name: 'name',
          description: 'description',
          units: 10,
        ),
      ],
    );
    when(() => ship.cargo).thenReturn(shipCargo);
    final cooldown = Cooldown(
      shipSymbol: shipSymbol.symbol,
      remainingSeconds: 10,
      expiration: now.add(const Duration(seconds: 10)),
      totalSeconds: 21,
    );
    when(() => ship.cooldown).thenReturn(cooldown);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipEngine.speed).thenReturn(10);
    when(() => caches.marketPrices.pricesFor(tradeSymbol)).thenReturn([]);

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..mineJob = MineJob(mine: symbol, market: symbol);

    expect(
      () async => await travelAndSellCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      ),
      // No market for diamonds (would need to mock markets above).
      throwsA(isA<JobException>()),
    );
  });

  test('transferToHaulersOrWait', () async {
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
    const tradeSymbol = TradeSymbol.DIAMONDS;
    final shipCargo = ShipCargo(
      capacity: 60,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: tradeSymbol,
          name: 'name',
          description: 'description',
          units: 10,
        ),
      ],
    );
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipEngine.speed).thenReturn(10);
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);

    when(() => caches.marketPrices.pricesFor(tradeSymbol)).thenReturn([]);

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..mineJob = MineJob(mine: symbol, market: symbol);

    final hauler = _MockShip();
    final haulerFrame = _MockShipFrame();
    when(() => hauler.frame).thenReturn(haulerFrame);
    when(() => haulerFrame.symbol).thenReturn(ShipFrameSymbolEnum.SHUTTLE);
    final haulerNav = shipNav; // Can just share for now.
    when(() => hauler.nav).thenReturn(haulerNav);
    final haulerCargo = ShipCargo(
      capacity: 60,
      units: 0,
      inventory: [],
    );
    final haulerNavRoute = _MockShipNavRoute();
    when(() => haulerNav.route).thenReturn(haulerNavRoute);
    final arrival = now.add(const Duration(minutes: 1));
    when(() => haulerNavRoute.arrival).thenReturn(arrival);
    when(() => hauler.cargo).thenReturn(haulerCargo);
    const haulerSymbol = ShipSymbol('S', 2);
    when(() => hauler.symbol).thenReturn(haulerSymbol.symbol);

    final squad = MiningSquad(state.mineJob!)..ships.addAll([ship, hauler]);
    when(() => centralCommand.squadForShip(ship)).thenReturn(squad);

    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.transferCargo(
        shipSymbol.symbol,
        transferCargoRequest: TransferCargoRequest(
          shipSymbol: haulerSymbol.symbol,
          tradeSymbol: tradeSymbol,
          units: 10,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        TransferCargo200Response(
          data: Jettison200ResponseData(
            cargo: shipCargo,
          ),
        ),
      ),
    );

    final logger = _MockLogger();

    final result = await runWithLogger(logger, () async {
      final result = await transferToHaulersOrWait(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: getNow,
      );
      return result;
    });
    expect(result.waitTime, arrival);
  });

  test('describeSurvey', () {
    final marketPrices = _MockMarketPrices();
    final marketSymbol = WaypointSymbol.fromString('S-A-W');
    const tradeSymbol = TradeSymbol.DIAMONDS;
    when(
      () =>
          marketPrices.recentSellPrice(tradeSymbol, marketSymbol: marketSymbol),
    ).thenReturn(100);
    final survey = Survey(
      expiration: DateTime(2021),
      signature: 'sig',
      symbol: marketSymbol.waypoint,
      deposits: [SurveyDeposit(symbol: tradeSymbol.value)],
      size: SurveySizeEnum.SMALL,
    );
    final description = describeSurvey(
      survey,
      marketPrices,
      marketSymbol,
    );
    expect(description, 'sig SMALL DIAMONDS ev 100c');
  });
}
