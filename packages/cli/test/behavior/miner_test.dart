import 'package:cli/behavior/job.dart';
import 'package:cli/behavior/miner.dart';
import 'package:cli/caches.dart';
import 'package:cli/central_command.dart';
import 'package:cli/logger.dart';
import 'package:cli/plan/mining.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockDatabase extends Mock implements Database {}

class _MockExtractionStore extends Mock implements ExtractionStore {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketListingStore extends Mock implements MarketListingStore {}

class _MockMarketPriceSnapshot extends Mock implements MarketPriceSnapshot {}

class _MockMarketPriceStore extends Mock implements MarketPriceStore {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockSurveyStore extends Mock implements SurveyStore {}

class _MockTransactionStore extends Mock implements TransactionStore {}

void main() {
  test('surveyWorthMining with no surveys', () async {
    final db = _MockDatabase();
    final marketPrices = _MockMarketPriceSnapshot();
    final symbol = WaypointSymbol.fromString('S-E-A');

    final surveyStore = _MockSurveyStore();
    when(() => db.surveys).thenReturn(surveyStore);

    when(
      () => surveyStore.recentAt(symbol, count: 100),
    ).thenAnswer((_) async => []);
    final surveys = await surveysWorthMining(
      db,
      marketPrices,
      surveyWaypointSymbol: symbol,
      marketForGood: {},
    );
    expect(surveys, isEmpty);
  });

  test('surveyWorthMining', () async {
    final db = _MockDatabase();

    final surveyStore = _MockSurveyStore();
    when(() => db.surveys).thenReturn(surveyStore);

    final marketPrices = _MockMarketPriceSnapshot();
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
                symbol: (i == 0) ? TradeSymbol.DIAMONDS : TradeSymbol.ALUMINUM,
              ),
            ],
            size: SurveySize.SMALL,
          ),
        ),
    ];
    when(
      () => surveyStore.recentAt(waypointSymbol, count: 100),
    ).thenAnswer((_) => Future.value(surveys));
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
      marketForGood: {
        TradeSymbol.DIAMONDS: waypointSymbol,
        TradeSymbol.ALUMINUM: waypointSymbol,
      },
      getNow: getNow,
    );
    expect(
      worthMining.first.survey.deposits.first.symbol,
      TradeSymbol.DIAMONDS,
    );
  });
  test('advanceMiner smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();

    final surveyStore = _MockSurveyStore();
    when(() => db.surveys).thenReturn(surveyStore);

    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbol.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
        strength: 10,
      ),
    ]);

    when(
      () => caches.waypoints.hasMarketplace(waypointSymbol),
    ).thenAnswer((_) async => true);
    when(
      () => caches.waypoints.hasShipyard(waypointSymbol),
    ).thenAnswer((_) async => false);
    when(
      () => caches.waypoints.canBeMined(waypointSymbol),
    ).thenAnswer((_) async => true);

    final shipCargo = ShipCargo(capacity: 60, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..extractionJob = ExtractionJob(
        source: waypointSymbol,
        marketForGood: const {},
        extractionType: ExtractionType.mine,
      );

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
    when(() => fleetApi.extractResources(shipSymbol.symbol)).thenAnswer(
      (_) => Future.value(
        ExtractResources201Response(
          data: ExtractResources201ResponseData(
            cooldown: cooldownAfterMining,
            extraction: Extraction(
              shipSymbol: shipSymbol.symbol,
              yield_: ExtractionYield(symbol: TradeSymbol.DIAMONDS, units: 10),
            ),
            cargo: shipCargo,
          ),
        ),
      ),
    );
    when(
      () => surveyStore.recentAt(waypointSymbol, count: 100),
    ).thenAnswer((_) async => []);

    final extractionStore = _MockExtractionStore();
    when(() => db.extractions).thenReturn(extractionStore);

    registerFallbackValue(ExtractionRecord.fallbackValue());
    when(() => extractionStore.insert(any())).thenAnswer((_) async {});

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
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});
    registerFallbackValue(const SystemSymbol.fallbackValue());

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);
    when(
      () => marketPriceStore.snapshotInSystem(any()),
    ).thenAnswer((_) async => MarketPriceSnapshot([]));

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
    verify(() => ship.cooldown = cooldownAfterMining).called(1);
  });

  test('maxExtractedUnits', () {
    final ship = _MockShip();
    when(() => ship.cargo).thenReturn(ShipCargo(capacity: 60, units: 0));
    final laser1 = ShipMount(
      symbol: ShipMountSymbol.MINING_LASER_I,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(),
    );
    final laser2 = ShipMount(
      symbol: ShipMountSymbol.MINING_LASER_II,
      name: '',
      description: '',
      strength: 25,
      requirements: ShipRequirements(),
    );
    final laser3 = ShipMount(
      symbol: ShipMountSymbol.MINING_LASER_III,
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
      symbol: ShipMountSymbol.MINING_LASER_I,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(power: 1),
    );
    final laser2 = ShipMount(
      symbol: ShipMountSymbol.MINING_LASER_II,
      name: '',
      description: '',
      strength: 10,
      requirements: ShipRequirements(power: 2),
    );
    when(() => ship.mounts).thenReturn([laser1, laser2]);
    expect(cooldownTimeForExtraction(ship), 90);
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
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.systemString);
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
    when(() => ship.modules).thenReturn([]);
    when(() => caches.marketPrices.pricesFor(tradeSymbol)).thenReturn([]);

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..extractionJob = ExtractionJob(
        source: symbol,
        marketForGood: const {},
        extractionType: ExtractionType.mine,
      );

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);
    registerFallbackValue(const SystemSymbol.fallbackValue());
    when(
      () => marketPriceStore.snapshotInSystem(any()),
    ).thenAnswer((_) async => MarketPriceSnapshot([]));

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
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final symbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(symbol.systemString);
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
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.MINER);

    when(() => caches.marketPrices.pricesFor(tradeSymbol)).thenReturn([]);

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..extractionJob = ExtractionJob(
        source: symbol,
        marketForGood: const {},
        extractionType: ExtractionType.mine,
      );

    final hauler = _MockShip();
    final haulerFrame = _MockShipFrame();
    when(() => hauler.frame).thenReturn(haulerFrame);
    when(() => haulerFrame.symbol).thenReturn(ShipFrameSymbol.SHUTTLE);
    final haulerNav = _MockShipNav();
    when(() => hauler.nav).thenReturn(haulerNav);
    final haulerCargo = ShipCargo(capacity: 60, units: 0, inventory: []);
    final haulerNavRoute = _MockShipNavRoute();
    when(() => haulerNav.route).thenReturn(haulerNavRoute);
    when(() => haulerNav.waypointSymbol).thenReturn(symbol.waypoint);
    when(() => haulerNav.status).thenReturn(ShipNavStatus.IN_TRANSIT);
    final arrival = now.add(const Duration(minutes: 1));
    when(() => haulerNavRoute.arrival).thenReturn(arrival);
    when(() => hauler.cargo).thenReturn(haulerCargo);
    const haulerSymbol = ShipSymbol('S', 2);
    when(() => hauler.symbol).thenReturn(haulerSymbol);

    final squad = ExtractionSquad(state.extractionJob!)
      ..ships.addAll([ship, hauler]);
    when(() => centralCommand.squadForShip(ship)).thenReturn(squad);

    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.transferCargo(
        shipSymbol.symbol,
        TransferCargoRequest(
          shipSymbol: haulerSymbol.symbol,
          tradeSymbol: tradeSymbol,
          units: 10,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        TransferCargo200Response(
          data: TransferCargo200ResponseData(
            cargo: shipCargo,
            // Hack to give same cargo for both ships.
            targetCargo: shipCargo,
          ),
        ),
      ),
    );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});
    when(() => db.upsertShip(hauler)).thenAnswer((_) async {});

    final logger = _MockLogger();

    final paddedArrival = arrival.add(const Duration(seconds: 1));
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
    // Check for the hauler 1s (padding) after it arrives.
    expect(result.waitTime, paddedArrival);

    // transferOrSellCargo is just a wrapper and should work too.
    final orSell = await runWithLogger(logger, () async {
      final result = await transferOrSellCargo(
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
    expect(orSell.waitTime, paddedArrival);
  });

  test('emptyCargoIfNeededForMining', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    DateTime getNow() => now;
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(waypointSymbol.systemString);
    when(() => ship.mounts).thenReturn([
      ShipMount(
        symbol: ShipMountSymbol.MINING_LASER_II,
        name: '',
        description: '',
        requirements: ShipRequirements(),
        strength: 10,
      ),
    ]);

    const tradeSymbol = TradeSymbol.DIAMONDS;
    const cargoCapacity = 60;
    final shipCargo = ShipCargo(
      capacity: cargoCapacity,
      units: cargoCapacity,
      inventory: [
        ShipCargoItem(
          symbol: tradeSymbol,
          name: 'name',
          description: 'description',
          units: cargoCapacity,
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
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbol.MINER);

    when(() => caches.marketPrices.pricesFor(tradeSymbol)).thenReturn([]);

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(7);

    when(
      () => caches.waypoints.hasMarketplace(waypointSymbol),
    ).thenAnswer((_) async => true);
    when(
      () => caches.waypoints.hasShipyard(waypointSymbol),
    ).thenAnswer((_) async => false);
    when(
      () => caches.waypoints.canBeMined(waypointSymbol),
    ).thenAnswer((_) async => true);

    final marketPriceStore = _MockMarketPriceStore();
    when(() => db.marketPrices).thenReturn(marketPriceStore);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(waypointSymbol);
    when(
      () => marketPriceStore.hasRecentAt(any(), any()),
    ).thenAnswer((_) async => true);

    final market = Market(
      symbol: waypointSymbol.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: tradeSymbol,
          type: MarketTradeGoodType.IMPORT,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 100,
        ),
      ],
    );

    when(() => caches.markets.fromCache(waypointSymbol)).thenReturn(market);
    when(
      () => caches.markets.refreshMarket(waypointSymbol),
    ).thenAnswer((_) => Future.value(market));
    final fleetApi = _MockFleetApi();
    final agent = Agent.test();
    registerFallbackValue(agent);
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});

    final transaction = MarketTransaction(
      tradeSymbol: tradeSymbol.value,
      units: cargoCapacity,
      pricePerUnit: 100,
      totalPrice: cargoCapacity * 100,
      type: MarketTransactionType.SELL,
      shipSymbol: shipSymbol.symbol,
      waypointSymbol: waypointSymbol.waypoint,
      timestamp: now,
    );
    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    when(() => api.fleet).thenReturn(fleetApi);
    when(
      () => fleetApi.sellCargo(
        shipSymbol.symbol,
        SellCargoRequest(symbol: tradeSymbol, units: cargoCapacity),
      ),
    ).thenAnswer(
      (_) => Future.value(
        SellCargo201Response(
          data: SellCargo201ResponseData(
            agent: agent.toOpenApi(),
            cargo: ShipCargo(capacity: cargoCapacity, units: 0),
            transaction: transaction,
          ),
        ),
      ),
    );

    when(
      () => caches.marketPrices.recentSellPrice(
        tradeSymbol,
        marketSymbol: waypointSymbol,
      ),
    ).thenReturn(100);

    // Returning no systems will find no nearby markets, thus will jettison.
    when(
      () => caches.systems.waypointsInSystem(waypointSymbol.system),
    ).thenReturn([]);

    when(
      () => fleetApi.jettison(
        shipSymbol.symbol,
        JettisonRequest(symbol: tradeSymbol, units: cargoCapacity),
      ),
    ).thenAnswer(
      (_) => Future.value(
        Jettison200Response(
          data: Jettison200ResponseData(
            cargo: ShipCargo(capacity: cargoCapacity, units: 0),
          ),
        ),
      ),
    );

    when(() => centralCommand.minimumSurveys).thenReturn(10);
    when(() => centralCommand.surveyPercentileThreshold).thenReturn(0.9);

    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);

    when(() => marketListingStore.at(waypointSymbol)).thenAnswer((_) async {
      return null;
    });
    registerFallbackValue(TradeSymbol.ADVANCED_CIRCUITRY);
    when(
      () => marketPriceStore.medianPurchasePrice(any()),
    ).thenAnswer((_) async => 100);
    when(
      () => marketPriceStore.snapshotInSystem(any()),
    ).thenAnswer((_) async => MarketPriceSnapshot([]));

    when(
      () => marketListingStore.whichBuysInSystem(any(), any()),
    ).thenAnswer((_) async => []);

    final state = BehaviorState(shipSymbol, Behavior.miner)
      ..extractionJob = ExtractionJob(
        source: waypointSymbol,
        marketForGood: const {},
        extractionType: ExtractionType.mine,
      );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final logger = _MockLogger();

    final result = await runWithLogger(logger, () async {
      final result = await emptyCargoIfNeededForMining(
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

    expect(result.shouldReturn, true);
  });
}
