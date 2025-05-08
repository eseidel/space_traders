import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockApi extends Mock implements Api {}

class _MockChartingStore extends Mock implements ChartingStore {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarket extends Mock implements Market {}

class _MockMarketListingStore extends Mock implements MarketListingStore {}

class _MockMarketPrices extends Mock implements MarketPriceSnapshot {}

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardTransaction extends Mock implements ShipyardTransaction {}

class _MockSurveyStore extends Mock implements SurveyStore {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockTransactionStore extends Mock implements TransactionStore {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void main() {
  test('purchaseShip', () async {
    final Api api = _MockApi();
    final FleetApi fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final agent1 = Agent.test(credits: 1);
    final agent2 = Agent.test(credits: 2);

    // TODO(eseidel): Use Ship.test once that exists.
    final ship = Ship.fallbackValue();
    final responseData = PurchaseShip201ResponseData(
      agent: agent2.toOpenApi(),
      ship: ship.toOpenApi(),
      transaction: _MockShipyardTransaction(),
    );

    when(
      () => fleetApi.purchaseShip(
        purchaseShipRequest: any(named: 'purchaseShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(PurchaseShip201Response(data: responseData)),
    );

    final db = _MockDatabase();
    registerFallbackValue(agent1);
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});
    registerFallbackValue(Ship.fallbackValue());
    when(() => db.upsertShip(any())).thenAnswer((_) async {});

    final shipyardSymbol = WaypointSymbol.fromString('S-A-Y');
    const shipType = ShipType.PROBE;
    await purchaseShip(db, api, shipyardSymbol, shipType);
    registerFallbackValue(Ship.fallbackValue());
    verify(() => db.upsertShip(any())).called(1);
    verify(() => db.upsertAgent(any())).called(1);
  });

  test('setShipFlightMode', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipNav = _MockShipNav();
    final fuel = ShipFuel(current: 100, capacity: 200);
    final responseData = PatchShipNav200ResponseData(nav: shipNav, fuel: fuel);
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(PatchShipNav200Response(data: responseData)),
    );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    await setShipFlightMode(db, api, ship, ShipNavFlightMode.CRUISE);
    verify(() => ship.nav = shipNav).called(1);
    verify(() => ship.fuel = fuel).called(1);
  });

  test('undockIfNeeded', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.orbitShip(any())).thenAnswer(
      (invocation) => Future.value(
        OrbitShip200Response(
          data: OrbitShip200ResponseData(nav: _MockShipNav()),
        ),
      ),
    );
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    when(() => ship.emojiName).thenReturn('S');
    when(() => ship.symbol).thenReturn(ShipSymbol.fromString('S-1'));
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final logger = _MockLogger();
    await runWithLogger(logger, () => undockIfNeeded(db, api, ship));
    verifyNever(() => fleetApi.orbitShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    await runWithLogger(logger, () => undockIfNeeded(db, api, ship));
    verify(() => fleetApi.orbitShip(any())).called(1);
  });

  test('dockIfNeeded', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.dockShip(any())).thenAnswer(
      (invocation) => Future.value(
        DockShip200Response(
          data: OrbitShip200ResponseData(nav: _MockShipNav()),
        ),
      ),
    );
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(ShipSymbol.fromString('S-1'));
    when(() => ship.fleetRole).thenReturn(FleetRole.command);

    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final logger = _MockLogger();
    await runWithLogger(logger, () => dockIfNeeded(db, api, ship));
    verifyNever(() => fleetApi.dockShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    await runWithLogger(logger, () => dockIfNeeded(db, api, ship));
    verify(() => fleetApi.dockShip(any())).called(1);
  });

  test('navigateToLocalWaypoint does not change nav mode for probes', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn(ShipSymbol.fromString('S-1'));
    final shipNav = _MockShipNav();

    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('A');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    final shipFuel = ShipFuel(current: 0, capacity: 0);
    when(() => ship.fuel).thenReturn(shipFuel);
    final systemsSnapshot = SystemsSnapshot([]);

    final patchResponse = PatchShipNav200Response(
      data: PatchShipNav200ResponseData(nav: shipNav, fuel: shipFuel),
    );

    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer((_) => Future.value(patchResponse));

    when(
      () => fleetApi.navigateShip(
        any(),
        navigateShipRequest: any(named: 'navigateShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        NavigateShip200Response(
          data: NavigateShip200ResponseData(
            fuel: shipFuel,
            nav: _MockShipNav(),
          ),
        ),
      ),
    );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () => navigateToLocalWaypoint(
        db,
        api,
        systemsSnapshot,
        ship,
        WaypointSymbol.fromString('S-A-W'),
      ),
    );

    verifyNever(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    );
  });

  test('transferCargoAndLog', () async {
    final db = _MockDatabase();
    final shipCargo = ShipCargo(
      capacity: 100,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          units: 10,
          description: '',
          name: '',
        ),
      ],
    );
    final fromSymbol = ShipSymbol.fromString('S-1');
    final fromShip = _MockShip();
    when(() => fromShip.symbol).thenReturn(fromSymbol);
    when(() => fromShip.cargo).thenReturn(shipCargo);
    when(() => fromShip.fleetRole).thenReturn(FleetRole.command);

    final toSymbol = ShipSymbol.fromString('S-2');
    final toShip = _MockShip();
    when(() => toShip.symbol).thenReturn(toSymbol);
    when(() => toShip.cargo).thenReturn(shipCargo);
    when(() => toShip.fleetRole).thenReturn(FleetRole.command);

    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final logger = _MockLogger();

    when(
      () => fleetApi.transferCargo(
        fromSymbol.symbol,
        transferCargoRequest: TransferCargoRequest(
          tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
          units: 10,
          shipSymbol: toSymbol.symbol,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        TransferCargo200Response(
          data: Jettison200ResponseData(
            cargo: ShipCargo(capacity: 100, units: 0),
          ),
        ),
      ),
    );
    when(() => db.upsertShip(fromShip)).thenAnswer((_) async {});
    when(() => db.upsertShip(toShip)).thenAnswer((_) async {});

    final _ = await runWithLogger(
      logger,
      () => transferCargoAndLog(
        db,
        api,
        from: fromShip,
        to: toShip,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        units: 10,
      ),
    );
    verify(
      () => fleetApi.transferCargo(
        fromSymbol.symbol,
        transferCargoRequest: TransferCargoRequest(
          tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
          units: 10,
          shipSymbol: toSymbol.symbol,
        ),
      ),
    ).called(1);
  });

  test('refuelIfNeededAndLog', () async {
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    const tradeSymbol = TradeSymbol.FUEL;
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol);
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final logger = _MockLogger();

    final patchResponse = PatchShipNav200Response(
      data: PatchShipNav200ResponseData(
        nav: shipNav,
        fuel: ShipFuel(current: 0, capacity: 0),
      ),
    );

    final db = _MockDatabase();
    final agent = Agent.test();
    when(() => db.upsertAgent(agent)).thenAnswer((_) async {});
    final marketTransaction = MarketTransaction(
      waypointSymbol: waypointSymbol.waypoint,
      shipSymbol: shipSymbol.symbol,
      tradeSymbol: tradeSymbol.value,
      type: MarketTransactionTypeEnum.PURCHASE,
      units: 100,
      pricePerUnit: 10,
      totalPrice: 1000,
      timestamp: DateTime(2021),
    );

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});
    final market = _MockMarket();
    when(() => market.tradeGoods).thenReturn([]);

    when(
      () => fleetApi.refuelShip(
        shipSymbol.symbol,
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        RefuelShip200Response(
          data: RefuelShip200ResponseData(
            agent: agent.toOpenApi(),
            transaction: marketTransaction,
            fuel: ShipFuel(capacity: 1000, current: 1000),
          ),
        ),
      ),
    );

    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 1000, current: 634));
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(
      () => logger.warn(
        '🛸#1  command   Market does not sell fuel, not refueling.',
      ),
    ).called(1);

    when(() => market.tradeGoods).thenReturn([
      MarketTradeGood(
        symbol: tradeSymbol,
        tradeVolume: 100,
        supply: SupplyLevel.ABUNDANT,
        type: MarketTradeGoodTypeEnum.EXCHANGE,
        purchasePrice: 10,
        sellPrice: 11,
      ),
    ]);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 1000, current: 634));
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(() => fleetApi.refuelShip(shipSymbol.symbol)).called(1);
    verifyNever(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    );

    // Refueling will reset the flight mode to cruise.
    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer((_) => Future.value(patchResponse));
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.BURN);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.BURN);
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,

        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(
      () => fleetApi.patchShipNav(
        shipSymbol.symbol,
        patchShipNavRequest: PatchShipNavRequest(
          flightMode: ShipNavFlightMode.CRUISE,
        ),
      ),
    ).called(1);

    // Verify our "don't refuel for short miner trips" logic.
    clearInteractions(fleetApi);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    when(() => ship.fuel).thenReturn(
      ShipFuel(
        capacity: 1000,
        current: 501,
        // A short trip is currently < 20% of fuel capacity.
        consumed: ShipFuelConsumed(amount: 100, timestamp: DateTime(2021)),
      ),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,

        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verifyNever(
      () => fleetApi.refuelShip(
        shipSymbol.symbol,
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    );

    // It does refuel if our recent trip data is missing
    clearInteractions(fleetApi);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 1000, current: 501));
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,

        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(() => fleetApi.refuelShip(shipSymbol.symbol)).called(1);

    // It does refuel if our recent trip data has a large trip
    clearInteractions(fleetApi);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    when(() => ship.fuel).thenReturn(
      ShipFuel(
        capacity: 1000,
        current: 501,
        consumed: ShipFuelConsumed(amount: 300, timestamp: DateTime(2021)),
      ),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,

        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(() => fleetApi.refuelShip(shipSymbol.symbol)).called(1);

    // It will also refuel if our fuel is < 50% of capacity
    clearInteractions(fleetApi);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.MINER);
    when(() => ship.fuel).thenReturn(
      ShipFuel(
        capacity: 1000,
        current: 499,
        consumed: ShipFuelConsumed(amount: 100, timestamp: DateTime(2021)),
      ),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,

        market,
        ship,
        medianFuelPurchasePrice: 100,
      ),
    );
    verify(() => fleetApi.refuelShip(shipSymbol.symbol)).called(1);
  });

  test('sellAllCargoAndLog', () async {
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final emptyCargo = ShipCargo(capacity: 10, units: 0);
    when(() => ship.cargo).thenReturn(emptyCargo);
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final logger = _MockLogger();
    final db = _MockDatabase();
    final agent = Agent.test();
    when(() => db.upsertAgent(agent)).thenAnswer((_) async {});
    final market = _MockMarket();
    when(() => market.tradeGoods).thenReturn([
      MarketTradeGood(
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        tradeVolume: 100,
        supply: SupplyLevel.ABUNDANT,
        type: MarketTradeGoodTypeEnum.EXCHANGE,
        purchasePrice: 10,
        sellPrice: 11,
      ),
      MarketTradeGood(
        symbol: TradeSymbol.FABRICS,
        tradeVolume: 100,
        supply: SupplyLevel.ABUNDANT,
        type: MarketTradeGoodTypeEnum.EXCHANGE,
        purchasePrice: 10,
        sellPrice: 11,
      ),
    ]);
    final marketPrices = _MockMarketPrices();
    const accountingType = AccountingType.goods;

    final emptyTransactions = await runWithLogger(logger, () async {
      final result = await sellAllCargoAndLog(
        api,
        db,
        marketPrices,

        market,
        ship,
        accountingType,
      );
      return result;
    });
    expect(emptyTransactions, isEmpty);
    verifyNever(
      () => fleetApi.sellCargo(
        any(),
        sellCargoRequest: any(named: 'sellCargoRequest'),
      ),
    );
    verify(() => logger.info('🛸#1  command   No cargo to sell')).called(1);

    when(
      () => fleetApi.sellCargo(
        any(),
        sellCargoRequest: any(named: 'sellCargoRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        SellCargo201Response(
          data: SellCargo201ResponseData(
            agent: agent.toOpenApi(),
            cargo: ShipCargo(capacity: 10, units: 0),
            transaction: MarketTransaction(
              waypointSymbol: 'S-A-W',
              shipSymbol: shipSymbol.symbol,
              tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
              type: MarketTransactionTypeEnum.SELL,
              units: 5,
              pricePerUnit: 10,
              totalPrice: 50,
              timestamp: DateTime(2021),
            ),
          ),
        ),
      ),
    );

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    final shipCargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          units: 5,
          description: '',
          name: '',
        ),
        ShipCargoItem(
          symbol: TradeSymbol.FABRICS,
          units: 5,
          description: '',
          name: '',
        ),
      ],
    );
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    final transactions = await runWithLogger(logger, () async {
      final result = await sellAllCargoAndLog(
        api,
        db,
        marketPrices,

        market,
        ship,
        accountingType,
      );
      return result;
    });
    expect(transactions.length, 2);
  });

  test('jettisonCargoAndLog', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final logger = _MockLogger();

    final itemOne = ShipCargoItem(
      symbol: TradeSymbol.ADVANCED_CIRCUITRY,
      units: 5,
      description: '',
      name: '',
    );
    final itemTwo = ShipCargoItem(
      symbol: TradeSymbol.FABRICS,
      units: 5,
      description: '',
      name: '',
    );
    final shipCargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [itemOne, itemTwo],
    );
    when(() => ship.cargo).thenReturn(shipCargo);

    when(
      () => fleetApi.jettison(
        shipSymbol.symbol,
        jettisonRequest: JettisonRequest(
          symbol: itemOne.tradeSymbol,
          units: itemOne.units,
        ),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        Jettison200Response(
          data: Jettison200ResponseData(
            cargo: ShipCargo(capacity: 10, units: 0),
          ),
        ),
      ),
    );
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await jettisonCargoAndLog(db, api, ship, itemOne);
    });
    verify(
      () => fleetApi.jettison(
        any(),
        jettisonRequest: any(named: 'jettisonRequest'),
      ),
    ).called(1);
  });

  test('chartWaypointAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => systemsApi.getWaypoint(any(), any())).thenAnswer((_) async {
      return GetWaypoint200Response(
        data: Waypoint.test(waypointSymbol).toOpenApi(),
      );
    });
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    final waypointTraitCache = _MockWaypointTraitCache();

    final waypoint = Waypoint.test(
      waypointSymbol,
      type: WaypointType.ASTEROID_FIELD,
    );
    when(() => fleetApi.createChart(shipSymbol.symbol)).thenAnswer(
      (invocation) => Future.value(
        CreateChart201Response(
          data: CreateChart201ResponseData(
            waypoint: waypoint.toOpenApi(),
            chart: Chart(
              waypointSymbol: waypointSymbol.waypoint,
              submittedBy: 'S',
              submittedOn: DateTime(2021),
            ),
          ),
        ),
      ),
    );
    registerFallbackValue(waypoint);

    registerFallbackValue(ChartingRecord.fallbackValue());
    when(() => waypointTraitCache.addAll(any())).thenAnswer((_) async => {});

    final chartingStore = _MockChartingStore();
    when(() => db.charting).thenReturn(chartingStore);
    when(() => chartingStore.addWaypoint(any())).thenAnswer((_) async => {});

    final logger = _MockLogger();
    await runWithLogger(logger, () async {
      await chartWaypointAndLog(api, db, waypointTraitCache, ship);
    });

    // Waypoint already charted exceptions are caught and logged.
    when(() => fleetApi.createChart(shipSymbol.symbol)).thenAnswer(
      (invocation) =>
          throw ApiException(
            400,
            '{"error":{"message":"Waypoint already charted: X1-ZY63-71980E" '
            ',"code":4230,"data":{"waypointSymbol":"X1-ZY63-71980E"}}}',
          ),
    );
    await runWithLogger(logger, () async {
      await chartWaypointAndLog(api, db, waypointTraitCache, ship);
    });
    verify(
      () => logger.warn('🛸#1  command   A-W was already charted'),
    ).called(1);

    // Any other exception is thrown.
    when(
      () => fleetApi.createChart(shipSymbol.symbol),
    ).thenAnswer((invocation) => throw ApiException(401, 'other exception'));
    expect(
      () => runWithLogger(logger, () async {
        await chartWaypointAndLog(api, db, waypointTraitCache, ship);
      }),
      throwsA(predicate((e) => e is ApiException)),
    );
  });

  test('acceptContractAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    final contract = Contract.test(
      id: 'C-1',
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 1000),
      ),
    );
    final agent = Agent.test(credits: 0);
    when(() => db.upsertAgent(agent)).thenAnswer((_) async {});

    final logger = _MockLogger();

    when(() => contractsApi.acceptContract(any())).thenAnswer(
      (invocation) => Future.value(
        AcceptContract200Response(
          data: AcceptContract200ResponseData(
            contract: contract.toOpenApi(),
            agent: Agent.test(credits: 100).toOpenApi(),
          ),
        ),
      ),
    );

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    when(() => transactionStore.insert(any())).thenAnswer((_) async {});
    registerFallbackValue(Contract.fallbackValue());
    when(() => db.upsertContract(any())).thenAnswer((_) async {});
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await acceptContractAndLog(api, db, ship, contract);
    });
    verify(() => contractsApi.acceptContract(any())).called(1);
    verify(
      () => db.upsertAgent(
        any(that: isA<Agent>().having((a) => a.credits, 'credits', 100)),
      ),
    ).called(1);
    verify(() => db.upsertContract(any())).called(1);
  });

  test('completeContractAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    final contract = Contract.test(
      id: 'C-1',
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 1000),
      ),
    );
    final agent = Agent.test(credits: 0);
    when(() => db.upsertAgent(agent)).thenAnswer((_) async {});

    final logger = _MockLogger();

    when(() => contractsApi.fulfillContract(any())).thenAnswer(
      (invocation) => Future.value(
        FulfillContract200Response(
          data: AcceptContract200ResponseData(
            contract: contract.toOpenApi(),
            agent: Agent.test(credits: 1000).toOpenApi(),
          ),
        ),
      ),
    );

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);

    when(() => transactionStore.insert(any())).thenAnswer((_) async {});
    registerFallbackValue(Contract.fallbackValue());
    when(() => db.upsertContract(any())).thenAnswer((_) async {});
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await completeContractAndLog(api, db, ship, contract);
    });
    verify(() => contractsApi.fulfillContract(any())).called(1);
    verify(
      () => db.upsertAgent(
        any(that: isA<Agent>().having((a) => a.credits, 'credits', 1000)),
      ),
    ).called(1);
    verify(() => db.upsertContract(any())).called(1);
  });

  test('useJumpGateAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final startSymbol = WaypointSymbol.fromString('S-A-W');
    final endSymbol = WaypointSymbol.fromString('S-B-W');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(startSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(startSymbol.systemString);
    const shipNavStatus = ShipNavStatus.DOCKED;
    when(() => shipNav.status).thenReturn(shipNavStatus);
    final logger = _MockLogger();
    final agent = Agent.test(credits: 10000000);
    when(() => db.upsertAgent(agent)).thenAnswer((_) async {});
    final now = DateTime(2021);

    when(
      () => fleetApi.jumpShip(
        any(),
        jumpShipRequest: any(named: 'jumpShipRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        JumpShip200Response(
          data: JumpShip200ResponseData(
            nav: _MockShipNav(),
            cooldown: Cooldown(
              shipSymbol: shipSymbol.symbol,
              totalSeconds: 10,
              remainingSeconds: 0,
            ),
            transaction: MarketTransaction(
              waypointSymbol: startSymbol.waypoint,
              shipSymbol: shipSymbol.symbol,
              tradeSymbol: TradeSymbol.ANTIMATTER.value,
              type: MarketTransactionTypeEnum.PURCHASE,
              units: 1,
              pricePerUnit: 10000,
              totalPrice: 10000,
              timestamp: now,
            ),
            agent: agent.toOpenApi(),
          ),
        ),
      ),
    );
    when(() => fleetApi.orbitShip(shipSymbol.symbol)).thenAnswer(
      (invocation) => Future.value(
        OrbitShip200Response(
          data: OrbitShip200ResponseData(nav: _MockShipNav()),
        ),
      ),
    );

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);
    registerFallbackValue(Transaction.fallbackValue());
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await useJumpGateAndLog(
        api,
        db,

        ship,
        endSymbol,
        medianAntimatterPrice: null,
      );
    });
    verify(() => fleetApi.orbitShip(shipSymbol.symbol)).called(1);
    verify(
      () => fleetApi.jumpShip(
        shipSymbol.symbol,
        jumpShipRequest: JumpShipRequest(waypointSymbol: endSymbol.waypoint),
      ),
    ).called(1);
  });

  test('purchaseCargoAndLog with invalid amount', () async {
    await expectLater(
      () async => await purchaseCargoAndLog(
        _MockApi(),
        _MockDatabase(),
        _MockShip(),
        TradeSymbol.FUEL,
        AccountingType.fuel,
        amountToBuy: 0,
        medianPrice: 100,
      ),
      throwsArgumentError,
    );

    await expectLater(
      () async => await purchaseCargoAndLog(
        _MockApi(),
        _MockDatabase(),
        _MockShip(),
        TradeSymbol.FUEL,
        AccountingType.fuel,
        amountToBuy: -1,
        medianPrice: 100,
      ),
      throwsArgumentError,
    );
  });

  test('purchaseCargoAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.fleetRole).thenReturn(FleetRole.command);
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    final marketListingStore = _MockMarketListingStore();
    when(() => db.marketListings).thenReturn(marketListingStore);
    when(() => marketListingStore.at(waypointSymbol)).thenAnswer((_) async {
      return MarketListing(
        waypointSymbol: waypointSymbol,
        imports: const {TradeSymbol.FUEL},
      );
    });
    final agent = Agent.test(credits: 10000000);
    final cargo = ShipCargo(capacity: 100, units: 0);
    final transaction = MarketTransaction(
      waypointSymbol: waypointSymbol.waypoint,
      shipSymbol: shipSymbol.symbol,
      tradeSymbol: TradeSymbol.FUEL.value,
      type: MarketTransactionTypeEnum.PURCHASE,
      units: 1,
      pricePerUnit: 100,
      totalPrice: 100,
      timestamp: DateTime(2021),
    );
    when(
      () => fleetApi.purchaseCargo(
        any(),
        purchaseCargoRequest: any(named: 'purchaseCargoRequest'),
      ),
    ).thenAnswer((_) async {
      return PurchaseCargo201Response(
        data: SellCargo201ResponseData(
          agent: agent.toOpenApi(),
          cargo: cargo,
          transaction: transaction,
        ),
      );
    });
    when(() => db.upsertShip(ship)).thenAnswer((_) async {});
    when(() => db.transactions.insert(any())).thenAnswer((_) async {});
    when(() => db.upsertAgent(any())).thenAnswer((_) async {});
    registerFallbackValue(const MarketListing.fallbackValue());
    when(() => marketListingStore.upsert(any())).thenAnswer((_) async {});

    final transactionStore = _MockTransactionStore();
    when(() => db.transactions).thenReturn(transactionStore);
    when(() => transactionStore.insert(any())).thenAnswer((_) async {});

    final logger = _MockLogger();
    await runWithLogger(logger, () async {
      await purchaseCargoAndLog(
        api,
        db,
        ship,
        TradeSymbol.FUEL,
        AccountingType.fuel,
        amountToBuy: 1,
        medianPrice: 100,
      );
    });
  });

  test('recordSurveys', () async {
    final db = _MockDatabase();
    final surveyStore = _MockSurveyStore();
    when(() => db.surveys).thenReturn(surveyStore);

    registerFallbackValue(HistoricalSurvey.fallbackValue());
    when(() => surveyStore.insert(any())).thenAnswer((_) async {});

    Survey testSurvey(String signature) {
      return Survey(
        signature: signature,
        symbol: 'symbol',
        deposits: [],
        expiration: DateTime(2021),
        size: SurveySizeEnum.SMALL,
      );
    }

    final surveys = [testSurvey('survey1'), testSurvey('survey2')];
    recordSurveys(db, surveys);

    verify(() => db.surveys.insert(any())).called(2);
  });
}
