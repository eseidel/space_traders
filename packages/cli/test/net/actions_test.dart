import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/actions.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockDatabase extends Mock implements Database {}

class _MockChartingCache extends Mock implements ChartingCache {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarket extends Mock implements Market {}

class _MockMarketPrices extends Mock implements MarketPriceSnapshot {}

class _MockShip extends Mock implements Ship {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardTransaction extends Mock implements ShipyardTransaction {}

class _MockShipCache extends Mock implements ShipSnapshot {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypointTraitCache extends Mock implements WaypointTraitCache {}

void main() {
  test('purchaseShip', () async {
    final Api api = _MockApi();
    final FleetApi fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final shipCache = _MockShipCache();
    final agent1 = Agent.test(credits: 1);
    final agent2 = Agent.test(credits: 2);

    final responseData = PurchaseShip201ResponseData(
      agent: agent2.toOpenApi(),
      ship: _MockShip(),
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
    final agentCache = AgentCache(agent1, db);
    final shipyardSymbol = WaypointSymbol.fromString('S-A-Y');
    const shipType = ShipType.PROBE;
    await purchaseShip(
      db,
      api,
      shipCache,
      agentCache,
      shipyardSymbol,
      shipType,
    );
    verify(
      () => shipCache.updateShip(db, responseData.ship),
    ).called(1);
    expect(agentCache.agent, agent2);
  });

  test('setShipFlightMode', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipNav = _MockShipNav();
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S-Y');
    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(GetShipNav200Response(data: shipNav)),
    );
    final shipCache = _MockShipCache();

    await setShipFlightMode(db, api, shipCache, ship, ShipNavFlightMode.CRUISE);
    verify(() => ship.nav = shipNav).called(1);
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
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    final shipCache = _MockShipCache();
    final logger = _MockLogger();
    await runWithLogger(logger, () => undockIfNeeded(db, api, shipCache, ship));
    verifyNever(() => fleetApi.orbitShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    await runWithLogger(logger, () => undockIfNeeded(db, api, shipCache, ship));
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
    final shipCache = _MockShipCache();
    final ship = _MockShip();
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    final logger = _MockLogger();
    await runWithLogger(logger, () => dockIfNeeded(db, api, shipCache, ship));
    verifyNever(() => fleetApi.dockShip(any()));

    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    await runWithLogger(logger, () => dockIfNeeded(db, api, shipCache, ship));
    verify(() => fleetApi.dockShip(any())).called(1);
  });

  test('navigateToLocalWaypoint does not change nav mode for probes', () async {
    final db = _MockDatabase();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    when(() => ship.emojiName).thenReturn('S');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('A');
    when(() => shipNav.status).thenReturn(ShipNavStatus.IN_ORBIT);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    final shipFuel = ShipFuel(current: 0, capacity: 0);
    when(() => ship.fuel).thenReturn(shipFuel);
    final shipCache = _MockShipCache();
    final systemsCache = _MockSystemsCache();

    when(
      () => fleetApi.patchShipNav(
        any(),
        patchShipNavRequest: any(named: 'patchShipNavRequest'),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        GetShipNav200Response(data: _MockShipNav()),
      ),
    );

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

    final logger = _MockLogger();
    await runWithLogger(
      logger,
      () => navigateToLocalWaypoint(
        db,
        api,
        systemsCache,
        shipCache,
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
    final shipCargo = ShipCargo(capacity: 100, units: 10);
    final fromSymbol = ShipSymbol.fromString('S-1');
    final fromShip = _MockShip();
    when(() => fromShip.symbol).thenReturn(fromSymbol.symbol);
    when(() => fromShip.cargo).thenReturn(shipCargo);

    final toSymbol = ShipSymbol.fromString('S-2');
    final toShip = _MockShip();
    when(() => toShip.symbol).thenReturn(toSymbol.symbol);
    when(() => toShip.cargo).thenReturn(shipCargo);

    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipCache = _MockShipCache();
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

    final _ = await runWithLogger(
      logger,
      () => transferCargoAndLog(
        db,
        api,
        shipCache,
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
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol).thenReturn(ShipFrameSymbolEnum.CARRIER);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final shipCache = _MockShipCache();
    final logger = _MockLogger();

    final agent = Agent.test();
    final agentCache = _MockAgentCache();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agentCache.updateAgent(agent)).thenAnswer((_) async {});
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
    final db = _MockDatabase();
    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) async {});
    final market = _MockMarket();
    when(() => market.tradeGoods).thenReturn([]);
    final marketPrices = _MockMarketPrices();

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
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
      ),
    );
    verify(() => logger.warn('🛸#1  Market does not sell fuel, not refueling.'))
        .called(1);

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

    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
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
    ).thenAnswer(
      (invocation) => Future.value(GetShipNav200Response(data: shipNav)),
    );
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.BURN);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.BURN);
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
      ),
    );
    verify(
      () => fleetApi.patchShipNav(
        shipSymbol.symbol,
        patchShipNavRequest:
            PatchShipNavRequest(flightMode: ShipNavFlightMode.CRUISE),
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
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
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
    when(() => ship.fuel).thenReturn(
      ShipFuel(capacity: 1000, current: 501),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
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
        consumed: ShipFuelConsumed(
          amount: 300,
          timestamp: DateTime(2021),
        ),
      ),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
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
        consumed: ShipFuelConsumed(
          amount: 100,
          timestamp: DateTime(2021),
        ),
      ),
    );
    await runWithLogger(
      logger,
      () => refuelIfNeededAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        shipCache,
        market,
        ship,
      ),
    );
    verify(() => fleetApi.refuelShip(shipSymbol.symbol)).called(1);
  });

  test('sellAllCargoAndLog', () async {
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final emptyCargo = ShipCargo(capacity: 10, units: 0);
    when(() => ship.cargo).thenReturn(emptyCargo);
    final shipCache = _MockShipCache();
    final api = _MockApi();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final logger = _MockLogger();
    final agent = Agent.test();
    final agentCache = _MockAgentCache();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agentCache.updateAgent(agent)).thenAnswer((_) async {});
    final db = _MockDatabase();
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
        agentCache,
        market,
        shipCache,
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
    verify(() => logger.info('🛸#1  No cargo to sell')).called(1);

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
    when(() => db.insertTransaction(any())).thenAnswer((_) async {});

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

    final transactions = await runWithLogger(logger, () async {
      final result = await sellAllCargoAndLog(
        api,
        db,
        marketPrices,
        agentCache,
        market,
        shipCache,
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
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipCache = _MockShipCache();
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
        jettisonRequest:
            JettisonRequest(symbol: itemOne.tradeSymbol, units: itemOne.units),
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

    await runWithLogger(logger, () async {
      await jettisonCargoAndLog(db, api, shipCache, ship, itemOne);
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
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(waypointSymbol.waypoint);
    final chartingCache = _MockChartingCache();
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
    when(() => chartingCache.addWaypoint(any())).thenAnswer((_) async {});

    final logger = _MockLogger();
    await runWithLogger(logger, () async {
      await chartWaypointAndLog(api, chartingCache, waypointTraitCache, ship);
    });

    // Waypoint already charted exceptions are caught and logged.
    when(() => fleetApi.createChart(shipSymbol.symbol)).thenAnswer(
      (invocation) => throw ApiException(
        400,
        '{"error":{"message":"Waypoint already charted: X1-ZY63-71980E" '
        ',"code":4230,"data":{"waypointSymbol":"X1-ZY63-71980E"}}}',
      ),
    );
    await runWithLogger(logger, () async {
      await chartWaypointAndLog(api, chartingCache, waypointTraitCache, ship);
    });
    verify(() => logger.warn('🛸#1  A-W was already charted')).called(1);

    // Any other exception is thrown.
    when(() => fleetApi.createChart(shipSymbol.symbol)).thenAnswer(
      (invocation) => throw ApiException(401, 'other exception'),
    );
    expect(
      () => runWithLogger(logger, () async {
        await chartWaypointAndLog(api, chartingCache, waypointTraitCache, ship);
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
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
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
    final agentCache = _MockAgentCache();
    final agent = Agent.test();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agentCache.updateAgent(agent)).thenAnswer((_) async {});

    final logger = _MockLogger();

    when(
      () => contractsApi.acceptContract(any()),
    ).thenAnswer(
      (invocation) => Future.value(
        AcceptContract200Response(
          data: AcceptContract200ResponseData(
            contract: contract.toOpenApi(),
            agent: agent.toOpenApi(),
          ),
        ),
      ),
    );

    when(() => db.insertTransaction(any())).thenAnswer((_) async {});
    registerFallbackValue(Contract.fallbackValue());
    when(() => db.upsertContract(any())).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await acceptContractAndLog(
        api,
        db,
        agentCache,
        ship,
        contract,
      );
    });
    verify(() => contractsApi.acceptContract(any())).called(1);
  });

  test('useJumpGateAndLog', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final ship = _MockShip();
    final shipSymbol = ShipSymbol.fromString('S-1');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final startSymbol = WaypointSymbol.fromString('S-A-W');
    final endSymbol = WaypointSymbol.fromString('S-B-W');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(startSymbol.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(startSymbol.systemString);
    const shipNavStatus = ShipNavStatus.DOCKED;
    when(() => shipNav.status).thenReturn(shipNavStatus);
    final shipCache = _MockShipCache();
    final logger = _MockLogger();
    final agent = Agent.test(credits: 10000000);
    final agentCache = _MockAgentCache();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agentCache.updateAgent(agent)).thenAnswer((_) async {});
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

    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) async {});

    await runWithLogger(logger, () async {
      await useJumpGateAndLog(
        api,
        db,
        agentCache,
        shipCache,
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
}
