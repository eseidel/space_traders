import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

import '../cache/caches_mock.dart';

class _MockApi extends Mock implements Api {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFrame extends Mock implements ShipFrame {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsApi extends Mock implements SystemsApi {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

void main() {
  setUpAll(() {
    registerFallbackValue(ShipSpec.fallbackValue());
  });

  test('advanceTrader smoke test', () async {
    registerFallbackValue(Duration.zero);
    const shipSymbol = ShipSymbol('S', 1);

    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(false);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(10);
    final caches = mockCaches();

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    final shipFuel = _MockShipFuel();
    when(() => ship.fuel).thenReturn(shipFuel);
    when(() => shipFuel.capacity).thenReturn(0);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(start.systemString);

    final market = Market(
      symbol: start.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 100,
          sellPrice: 101,
        ),
      ],
    );
    when(() => caches.markets.fromCache(start)).thenReturn(market);
    when(() => caches.markets.refreshMarket(start)).thenAnswer(
      (_) => Future.value(market),
    );

    when(
      () => caches.marketPrices.hasRecentData(
        start,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    registerFallbackValue(start);
    when(() => caches.waypoints.hasMarketplace(start))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(start))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.hasMarketplace(end))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(end))
        .thenAnswer((_) async => false);

    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 200,
      ),
      cargoSize: 10,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
        fuelCapacity: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    when(
      () => centralCommand.findNextDealAndLog(
        caches.agent,
        caches.contracts,
        caches.marketPrices,
        caches.systems,
        caches.systemConnectivity,
        caches.routePlanner,
        ship,
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenReturn(costedDeal);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(1);

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([]);

    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);
    registerFallbackValue(agent);
    when(() => caches.agent.updateAgent(any()))
        .thenAnswer((_) => Future.value());

    final state = BehaviorState(shipSymbol, Behavior.trader);

    when(
      () => fleetApi.purchaseCargo(
        shipSymbol.symbol,
        purchaseCargoRequest: PurchaseCargoRequest(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          units: 10,
        ),
      ),
    ).thenAnswer(
      (invocation) => Future.value(
        PurchaseCargo201Response(
          data: SellCargo201ResponseData(
            agent: agent.toOpenApi(),
            cargo: shipCargo,
            transaction: MarketTransaction(
              waypointSymbol: start.waypoint,
              shipSymbol: shipSymbol.symbol,
              tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
              units: 10,
              totalPrice: 100,
              pricePerUnit: 10,
              type: MarketTransactionTypeEnum.PURCHASE,
              timestamp: DateTime(2021),
            ),
          ),
        ),
      ),
    );
    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceTrader(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(waitUntil, isNull);
  });

  test('trader buys fuel before embarking', () async {
    // We already have a deal.
    // We're at the source destination.
    // We have enough credits to buy the fuel.
    // We already bought our cargo.
    // Make sure we buy fuel before we go.

    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(false);
    final caches = mockCaches();

    // This ship uses fuel.
    const fuelCapacity = 1000;
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 1000));
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    final shipFrame = _MockShipFrame();
    when(() => ship.frame).thenReturn(shipFrame);
    when(() => shipFrame.symbol)
        .thenReturn(ShipFrameSymbolEnum.LIGHT_FREIGHTER);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    // We do not need to dock.
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(start.systemString);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    // Needed by navigateShipAndLog to show time left.
    final arrivalTime = DateTime(2022);
    final departureTime = DateTime(2021);
    final departure = ShipNavRouteWaypoint(
      symbol: start.waypoint,
      type: WaypointType.ASTEROID,
      systemSymbol: start.systemString,
      x: 0,
      y: 0,
    );
    when(() => shipNav.route).thenReturn(
      ShipNavRoute(
        destination: ShipNavRouteWaypoint(
          symbol: end.waypoint,
          type: WaypointType.ASTEROID,
          systemSymbol: end.systemString,
          x: 0,
          y: 0,
        ),
        origin: departure,
        departureTime: departureTime,
        arrival: arrivalTime,
      ),
    );

    final shipEngine = _MockShipEngine();
    const shipSpeed = 10;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    when(() => ship.engine).thenReturn(shipEngine);

    registerFallbackValue(Duration.zero);
    when(
      () => caches.marketPrices.hasRecentData(
        start,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    when(() => caches.waypoints.hasMarketplace(start))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(start))
        .thenAnswer((_) async => false);
    when(() => caches.waypoints.hasMarketplace(end))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(end))
        .thenAnswer((_) async => false);

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: fuelCapacity,
      shipSpeed: 10,
    );
    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 20,
      ),
      cargoSize: 10,
      transactions: [],
      startTime: DateTime(2021),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    final market = Market(
      symbol: start.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          tradeVolume: 10,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 10,
          sellPrice: 20,
        ),
        // Sells fuel so we can refuel.
        MarketTradeGood(
          symbol: TradeSymbol.FUEL,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 100,
          sellPrice: 110,
        ),
      ],
    );
    when(() => caches.markets.fromCache(start)).thenReturn(market);
    when(() => caches.markets.refreshMarket(start)).thenAnswer(
      (_) => Future.value(market),
    );

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(10);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([
      ShipCargoItem(
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        name: '',
        description: '',
        units: 10,
      ),
    ]);

    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);
    registerFallbackValue(agent);
    when(() => caches.agent.updateAgent(any()))
        .thenAnswer((_) => Future.value());

    final transaction = MarketTransaction(
      pricePerUnit: 100,
      units: 1,
      totalPrice: 100,
      type: MarketTransactionTypeEnum.PURCHASE,
      tradeSymbol: TradeSymbol.FUEL.value,
      waypointSymbol: start.waypoint,
      shipSymbol: shipSymbol.symbol,
      timestamp: DateTime(2021),
    );
    when(
      () => fleetApi.refuelShip(
        shipSymbol.symbol,
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        RefuelShip200Response(
          data: RefuelShip200ResponseData(
            agent: agent.toOpenApi(),
            fuel: ShipFuel(current: fuelCapacity, capacity: fuelCapacity),
            transaction: transaction,
          ),
        ),
      ),
    );
    when(() => caches.systems.waypointsInSystem(start.system)).thenReturn([]);
    registerFallbackValue(start.system);
    // when(
    //   () => caches.systemConnectivity.canJumpBetweenSystemSymbols(
    //     any(),
    //     any(),
    //   ),
    // ).thenReturn(true);
    final state = BehaviorState(shipSymbol, Behavior.trader, deal: costedDeal);

    when(
      () => fleetApi.sellCargo(
        shipSymbol.symbol,
        sellCargoRequest: any(named: 'sellCargoRequest'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        SellCargo201Response(
          data: SellCargo201ResponseData(
            agent: agent.toOpenApi(),
            cargo: shipCargo,
            transaction: MarketTransaction(
              waypointSymbol: start.waypoint,
              shipSymbol: shipSymbol.symbol,
              tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
              units: 10,
              totalPrice: 100,
              pricePerUnit: 10,
              type: MarketTransactionTypeEnum.SELL,
              timestamp: DateTime(2021),
            ),
          ),
        ),
      ),
    );
    when(() => fleetApi.orbitShip(shipSymbol.symbol)).thenAnswer(
      (_) => Future.value(
        OrbitShip200Response(
          data: OrbitShip200ResponseData(
            nav: shipNav..status = ShipNavStatus.IN_ORBIT,
          ),
        ),
      ),
    );
    when(
      () => fleetApi.navigateShip(
        shipSymbol.symbol,
        navigateShipRequest: NavigateShipRequest(waypointSymbol: end.waypoint),
      ),
    ).thenAnswer(
      (_) => Future.value(
        NavigateShip200Response(
          data: NavigateShip200ResponseData(
            fuel: ShipFuel(
              current: fuelCapacity - 100,
              capacity: fuelCapacity,
              consumed:
                  ShipFuelConsumed(amount: 100, timestamp: DateTime(2020)),
            ),
            nav: shipNav..status = ShipNavStatus.IN_TRANSIT,
          ),
        ),
      ),
    );

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(10);
    when(
      () => caches.marketPrices.pricesFor(
        TradeSymbol.ADVANCED_CIRCUITRY,
        waypointSymbol: any(named: 'waypointSymbol'),
      ),
    ).thenReturn([
      MarketPrice(
        waypointSymbol: start,
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 10,
        timestamp: DateTime(2021),
        activity: ActivityLevel.WEAK,
      ),
    ]);

    when(
      () => caches.routePlanner.planRoute(
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenReturn(routePlan);
    registerFallbackValue(Transaction.fallbackValue());
    when(() => db.insertTransaction(any())).thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final result = await runWithLogger(
      logger,
      () => doTraderGetCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    verify(
      () => fleetApi.refuelShip(
        shipSymbol.symbol,
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    ).called(1);
    expect(result.isComplete, isTrue);
  });

  test('trade contracts smoke test', () async {
    registerFallbackValue(Duration.zero);
    const shipSymbol = ShipSymbol('S', 1);
    final now = DateTime(2021);

    final api = _MockApi();
    final db = _MockDatabase();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(true);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(1);
    final caches = mockCaches();
    when(() => caches.contracts.activeContracts).thenReturn([]);
    final contract = Contract(
      id: 'id',
      factionSymbol: 'factionSymbol',
      type: ContractTypeEnum.PROCUREMENT,
      deadlineToAccept: DateTime(2021),
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
      ),
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );

    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);

    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    when(
      () => contractsApi.getContracts(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) => Future.value(
        GetContracts200Response(meta: Meta(total: 0), data: []),
      ),
    );
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.negotiateContract(any())).thenAnswer(
      (_) => Future.value(
        NegotiateContract200Response(
          data: NegotiateContract200ResponseData(
            contract: contract.toOpenApi(),
          ),
        ),
      ),
    );

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([]);

    final shipLocation = WaypointSymbol.fromString('S-A-W');
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(shipLocation.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(shipLocation.systemString);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 100, current: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    registerFallbackValue(start);

    final startWaypoint = SystemWaypoint.test(start);
    final endWaypoint = SystemWaypoint.test(end);
    final shipLocationWaypoint = SystemWaypoint.test(shipLocation);

    when(() => caches.systems.waypoint(start)).thenReturn(startWaypoint);
    when(() => caches.systems.waypoint(end)).thenReturn(endWaypoint);
    when(() => caches.systems.waypoint(shipLocation))
        .thenReturn(shipLocationWaypoint);

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: shipLocation,
          endSymbol: start,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: 10,
      shipSpeed: 10,
    );

    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.FUEL,
        purchasePrice: 10,
        sellPrice: 200,
      ),
      cargoSize: 100,
      transactions: [],
      startTime: DateTime(2021),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );
    when(
      () => centralCommand.findNextDealAndLog(
        caches.agent,
        caches.contracts,
        caches.marketPrices,
        caches.systems,
        caches.systemConnectivity,
        caches.routePlanner,
        ship,
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenReturn(costedDeal);
    when(() => centralCommand.otherTraderSystems(shipSymbol)).thenReturn([]);
    when(() => caches.marketPrices.prices).thenReturn([]);

    final state = BehaviorState(shipSymbol, Behavior.trader);

    when(
      () => caches.routePlanner.planRoute(
        any(),
        start: shipLocation,
        end: start,
      ),
    ).thenReturn(routePlan);

    when(() => fleetApi.orbitShip(shipSymbol.symbol)).thenAnswer(
      (_) async =>
          OrbitShip200Response(data: OrbitShip200ResponseData(nav: shipNav)),
    );
    when(
      () => fleetApi.navigateShip(
        shipSymbol.symbol,
        navigateShipRequest:
            NavigateShipRequest(waypointSymbol: start.waypoint),
      ),
    ).thenAnswer(
      (_) async => NavigateShip200Response(
        data: NavigateShip200ResponseData(
          fuel: ShipFuel(
            capacity: 100,
            current: 100,
            consumed: ShipFuelConsumed(amount: 100, timestamp: now),
          ),
          nav: shipNav,
        ),
      ),
    );
    final shipNavRoute = _MockShipNavRoute();
    when(() => shipNav.route).thenReturn(shipNavRoute);
    when(() => shipNavRoute.arrival).thenReturn(now);
    when(() => shipNavRoute.departureTime).thenReturn(now);
    when(() => shipNavRoute.origin).thenReturn(
      ShipNavRouteWaypoint(
        symbol: shipLocation.waypoint,
        type: WaypointType.ASTEROID,
        systemSymbol: shipLocation.systemString,
        x: 0,
        y: 0,
      ),
    );
    when(() => shipNavRoute.destination).thenReturn(
      ShipNavRouteWaypoint(
        symbol: start.waypoint,
        type: WaypointType.ASTEROID,
        systemSymbol: start.systemString,
        x: 0,
        y: 0,
      ),
    );

    registerFallbackValue(Contract.fallbackValue());
    when(() => db.upsertContract(any())).thenAnswer((_) async {});

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceTrader(
        api,
        db,
        centralCommand,
        caches,
        state,
        ship,
      ),
    );
    expect(waitUntil, now);
  });

  test('handleUnwantedCargoIfNeeded smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    final ship = _MockShip();
    final shipCargo = ShipCargo(capacity: 10, units: 0);
    when(() => ship.cargo).thenReturn(shipCargo);
    final state = BehaviorState(const ShipSymbol('S', 1), Behavior.trader);

    final result = await handleUnwantedCargoIfNeeded(
      api,
      db,
      centralCommand,
      caches,
      ship,
      state,
      null,
      null,
    );
    expect(result.isComplete, isTrue);
  });

  test('logCompletedDeal', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 200,
      ),
      cargoSize: 10,
      transactions: [
        Transaction.fallbackValue(),
        Transaction.fallbackValue(),
      ],
      startTime: DateTime(2021).toUtc(),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: 10,
            fuelUsed: 10,
          ),
        ],
        fuelCapacity: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S-1');
    final logger = _MockLogger();
    DateTime getNow() => DateTime(2021).toUtc();
    runWithLogger(
      logger,
      () => logCompletedDeal(ship, costedDeal, getNow: getNow),
    );
    verify(
      () => logger.err(
        '🛸#1  Expected 1,800c profit (180c/s), got -4c (-4c/s) in 00:00:00, expected 00:00:10',
      ),
    ).called(1);
  });
  test('doTraderDeliverCargo travels to destination', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-B');
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipCargo = ShipCargo(capacity: 10, units: 10);
    when(() => ship.cargo).thenReturn(shipCargo);
    const fuelCapacity = 100;
    when(() => ship.fuel)
        .thenReturn(ShipFuel(current: fuelCapacity, capacity: fuelCapacity));
    final shipEngine = _MockShipEngine();
    const shipSpeed = 10;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    when(() => ship.engine).thenReturn(shipEngine);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: 10,
      shipSpeed: 10,
    );
    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 200,
      ),
      cargoSize: 10,
      transactions: [
        Transaction.fallbackValue(),
        Transaction.fallbackValue(),
      ],
      startTime: DateTime(2021).toUtc(),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    when(
      () => caches.routePlanner.planRoute(
        any(),
        start: any(named: 'start'),
        end: any(named: 'end'),
      ),
    ).thenReturn(routePlan);

    when(() => caches.systems.waypoint(start)).thenReturn(
      SystemWaypoint.test(start),
    );
    when(() => caches.systems.waypoint(end)).thenReturn(
      SystemWaypoint.test(end),
    );

    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    when(() => fleetApi.orbitShip(shipSymbol.symbol)).thenAnswer(
      (_) => Future.value(
        OrbitShip200Response(
          data: OrbitShip200ResponseData(
            nav: shipNav..status = ShipNavStatus.IN_ORBIT,
          ),
        ),
      ),
    );
    when(
      () => fleetApi.navigateShip(
        shipSymbol.symbol,
        navigateShipRequest: NavigateShipRequest(waypointSymbol: end.waypoint),
      ),
    ).thenAnswer(
      (_) => Future.value(
        NavigateShip200Response(
          data: NavigateShip200ResponseData(
            fuel: ShipFuel(
              current: fuelCapacity - 100,
              capacity: fuelCapacity,
              consumed:
                  ShipFuelConsumed(amount: 100, timestamp: DateTime(2020)),
            ),
            nav: shipNav..status = ShipNavStatus.IN_TRANSIT,
          ),
        ),
      ),
    );
    // Needed by navigateShipAndLog to show time left.
    final arrivalTime = DateTime(2022);
    final departureTime = DateTime(2021);
    final departure = SystemWaypoint.test(start).toShipNavRouteWaypoint();
    when(() => shipNav.route).thenReturn(
      ShipNavRoute(
        destination: SystemWaypoint.test(end).toShipNavRouteWaypoint(),
        origin: departure,
        departureTime: departureTime,
        arrival: arrivalTime,
      ),
    );

    final state = BehaviorState(const ShipSymbol('S', 1), Behavior.trader)
      ..deal = costedDeal;

    final logger = _MockLogger();
    final result = await runWithLogger(
      logger,
      () => doTraderDeliverCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(result.waitTime, arrivalTime);
  });

  test('doTraderDeliverCargo arbitrage', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    when(() => shipNav.waypointSymbol).thenReturn(end.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(end.systemString);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipCargo = ShipCargo(capacity: 10, units: 10);
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 100, current: 100));

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: 10,
      shipSpeed: 10,
    );
    final costedDeal = CostedDeal(
      deal: Deal.test(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 200,
      ),
      cargoSize: 10,
      transactions: [
        Transaction.fallbackValue(),
        Transaction.fallbackValue(),
      ],
      startTime: DateTime(2021).toUtc(),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    when(() => caches.waypoints.hasMarketplace(end))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(end))
        .thenAnswer((_) async => false);

    final market = Market(
      symbol: end.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 100,
          sellPrice: 101,
        ),
      ],
    );
    when(() => caches.markets.fromCache(end)).thenReturn(market);
    when(() => caches.markets.refreshMarket(end)).thenAnswer(
      (_) => Future.value(market),
    );

    when(
      () => caches.marketPrices.hasRecentData(
        end,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    final state = BehaviorState(const ShipSymbol('S', 1), Behavior.trader)
      ..deal = costedDeal;

    final logger = _MockLogger();
    final result = await runWithLogger(
      logger,
      () => doTraderDeliverCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(result.isComplete, isTrue);
  });

  test('doTraderDeliverCargo contract', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final now = DateTime(2021);
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    final agent = Agent.test();

    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    when(() => shipNav.waypointSymbol).thenReturn(end.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(end.systemString);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipCargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          name: '',
          description: '',
          units: 10,
        ),
      ],
    );
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 100, current: 100));

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: 10,
      shipSpeed: 10,
    );
    const tradeSymbol = TradeSymbol.ADVANCED_CIRCUITRY;
    final contract = Contract(
      id: 'contract_id',
      factionSymbol: 'factionSymbol',
      type: ContractTypeEnum.PROCUREMENT,
      deadlineToAccept: DateTime(2021),
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
        deliver: [
          ContractDeliverGood(
            tradeSymbol: tradeSymbol.value,
            destinationSymbol: end.waypoint,
            unitsFulfilled: 0,
            unitsRequired: 10,
          ),
        ],
      ),
      accepted: false,
      fulfilled: false,
      timestamp: now,
    );
    when(() => caches.contracts.contract(contract.id)).thenReturn(contract);
    final deal = Deal(
      destination: SellOpp.fromContract(
        waypointSymbol: end,
        tradeSymbol: tradeSymbol,
        price: 100,
        contractId: contract.id,
        maxUnits: 10,
      ),
      source: BuyOpp(
        MarketPrice(
          waypointSymbol: start,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 10,
          sellPrice: 11,
          tradeVolume: 100,
          // If these aren't UTC, they won't roundtrip through JSON correctly
          // because MarketPrice always converts to UTC in toJson.
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
    );

    final costedDeal = CostedDeal(
      deal: deal,
      cargoSize: 10,
      transactions: [
        Transaction.fallbackValue(),
        Transaction.fallbackValue(),
      ],
      startTime: DateTime(2021).toUtc(),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    when(() => caches.waypoints.hasMarketplace(end))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(end))
        .thenAnswer((_) async => false);
    final market = Market(
      symbol: end.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 100,
          sellPrice: 101,
        ),
      ],
    );
    when(() => caches.markets.fromCache(end)).thenReturn(market);
    when(() => caches.markets.refreshMarket(end)).thenAnswer(
      (_) => Future.value(market),
    );

    when(
      () => caches.marketPrices.hasRecentData(
        end,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    final contractsApi = _MockContractsApi();
    when(() => api.contracts).thenReturn(contractsApi);
    when(
      () => contractsApi.deliverContract(
        contract.id,
        deliverContractRequest: DeliverContractRequest(
          shipSymbol: shipSymbol.symbol,
          units: 10,
          tradeSymbol: tradeSymbol.value,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        DeliverContract200Response(
          data: DeliverContract200ResponseData(
            contract: contract.toOpenApi(),
            cargo: shipCargo,
          ),
        ),
      ),
    );

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

    when(() => caches.agent.agent).thenReturn(agent);
    registerFallbackValue(agent);
    when(() => caches.agent.updateAgent(any()))
        .thenAnswer((_) => Future.value());

    when(() => db.insertTransaction(any())).thenAnswer((_) => Future.value());
    registerFallbackValue(Contract.fallbackValue());
    when(() => db.upsertContract(any())).thenAnswer((_) async {});

    final state = BehaviorState(const ShipSymbol('S', 1), Behavior.trader)
      ..deal = costedDeal;

    final logger = _MockLogger();
    final result = await runWithLogger(
      logger,
      () => doTraderDeliverCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(result.isComplete, isTrue);
  });

  test('doTraderDeliverCargo construction', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = mockCaches();

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    when(() => shipNav.waypointSymbol).thenReturn(end.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(end.systemString);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    final shipCargo = ShipCargo(
      capacity: 10,
      units: 10,
      inventory: [
        ShipCargoItem(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          name: '',
          description: '',
          units: 10,
        ),
      ],
    );
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 100, current: 100));

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          seconds: 10,
          fuelUsed: 10,
        ),
      ],
      fuelCapacity: 10,
      shipSpeed: 10,
    );
    const tradeSymbol = TradeSymbol.ADVANCED_CIRCUITRY;
    final deal = Deal(
      destination: SellOpp.fromConstruction(
        waypointSymbol: end,
        tradeSymbol: tradeSymbol,
        price: 100,
        maxUnits: 10,
      ),
      source: BuyOpp(
        MarketPrice(
          waypointSymbol: start,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 10,
          sellPrice: 11,
          tradeVolume: 100,
          // If these aren't UTC, they won't roundtrip through JSON correctly
          // because MarketPrice always converts to UTC in toJson.
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
    );

    final costedDeal = CostedDeal(
      deal: deal,
      cargoSize: 10,
      transactions: [
        Transaction.fallbackValue(),
        Transaction.fallbackValue(),
      ],
      startTime: DateTime(2021).toUtc(),
      route: routePlan,
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );

    when(() => caches.waypoints.hasMarketplace(end))
        .thenAnswer((_) async => true);
    when(() => caches.waypoints.hasShipyard(end))
        .thenAnswer((_) async => false);
    final market = Market(
      symbol: end.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          tradeVolume: 100,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 100,
          sellPrice: 101,
        ),
      ],
    );
    when(() => caches.markets.fromCache(end)).thenReturn(market);
    when(() => caches.markets.refreshMarket(end)).thenAnswer(
      (_) => Future.value(market),
    );

    when(
      () => caches.marketPrices.hasRecentData(
        end,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);
    when(
      () => caches.construction
          .getConstruction(end, maxAge: any(named: 'maxAge')),
    ).thenAnswer(
      (_) async => Construction(
        symbol: end.waypoint,
        materials: [
          ConstructionMaterial(
            tradeSymbol: tradeSymbol,
            required_: 100,
            fulfilled: 10,
          ),
        ],
        isComplete: false,
      ),
    );

    final systemsApi = _MockSystemsApi();
    when(() => api.systems).thenReturn(systemsApi);
    final construction = Construction(
      symbol: end.waypoint,
      materials: [
        ConstructionMaterial(
          tradeSymbol: tradeSymbol,
          required_: 100,
          fulfilled: 20,
        ),
      ],
      isComplete: false,
    );
    when(
      () => systemsApi.supplyConstruction(
        end.systemString,
        end.waypoint,
        supplyConstructionRequest: SupplyConstructionRequest(
          shipSymbol: shipSymbol.symbol,
          tradeSymbol: tradeSymbol.value,
          units: 10,
        ),
      ),
    ).thenAnswer(
      (_) => Future.value(
        SupplyConstruction201Response(
          data: SupplyConstruction201ResponseData(
            construction: construction,
            cargo: shipCargo,
          ),
        ),
      ),
    );

    final agent = Agent.test();
    when(() => caches.agent.agent).thenReturn(agent);

    when(() => db.insertTransaction(any())).thenAnswer((_) => Future.value());

    when(caches.construction.allRecords).thenAnswer((_) async => []);
    when(
      () => caches.construction.updateConstruction(end, construction),
    ).thenAnswer((_) async => {});

    final state = BehaviorState(const ShipSymbol('S', 1), Behavior.trader)
      ..deal = costedDeal;

    final logger = _MockLogger();
    final result = await runWithLogger(
      logger,
      () => doTraderDeliverCargo(
        state,
        api,
        db,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    expect(result.isComplete, isTrue);
  });
}
