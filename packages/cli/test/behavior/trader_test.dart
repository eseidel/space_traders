import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:db/db.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockContractCache extends Mock implements ContractCache {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockDatabase extends Mock implements Database {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCache extends Mock implements ShipCache {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipNavRoute extends Mock implements ShipNavRoute {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockShipyardShipCache extends Mock implements ShipyardShipCache {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceTrader smoke test', () async {
    registerFallbackValue(Duration.zero);
    const shipSymbol = ShipSymbol('S', 1);

    final api = _MockApi();
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final shipyardPrices = _MockShipyardPrices();
    final contractCache = _MockContractCache();
    final routePlanner = _MockRoutePlanner();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(false);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(10);
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.contracts).thenReturn(contractCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    when(() => caches.routePlanner).thenReturn(routePlanner);
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);
    final shipyardShips = _MockShipyardShipCache();
    when(() => caches.shipyardShips).thenReturn(shipyardShips);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    final shipFuel = _MockShipFuel();
    when(() => ship.fuel).thenReturn(shipFuel);
    when(() => shipFuel.capacity).thenReturn(0);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(start.system);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(start.waypoint);
    when(() => waypoint.systemSymbol).thenReturn(start.system);
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.MARKETPLACE,
        name: '',
        description: '',
      ),
    ]);
    when(() => marketCache.marketForSymbol(start)).thenAnswer(
      (_) => Future.value(
        Market(
          symbol: end.waypoint,
          tradeGoods: [
            MarketTradeGood(
              symbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
              tradeVolume: 100,
              supply: MarketTradeGoodSupplyEnum.ABUNDANT,
              purchasePrice: 100,
              sellPrice: 101,
            ),
          ],
        ),
      ),
    );
    when(
      () => marketPrices.hasRecentMarketData(
        start,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    registerFallbackValue(start);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: start.systemSymbol,
        maxJumps: 1,
      ),
    ).thenReturn([]);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: start.systemSymbol,
        maxJumps: 1,
      ),
    ).thenReturn([]);

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
            duration: 10,
          ),
        ],
        fuelCapacity: 10,
        fuelUsed: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
    );

    when(
      () => centralCommand.findNextDeal(
        agentCache,
        contractCache,
        marketPrices,
        systemsCache,
        routePlanner,
        ship,
        maxJumps: any(named: 'maxJumps'),
        maxWaypoints: any(named: 'maxWaypoints'),
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenReturn(costedDeal);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(1);

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([]);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);
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
            agent: agent,
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
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final shipyardPrices = _MockShipyardPrices();
    final systemConnectivity = _MockSystemConnectivity();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(false);
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final routePlanner = _MockRoutePlanner();
    when(() => caches.routePlanner).thenReturn(routePlanner);
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);
    final shipyardShips = _MockShipyardShipCache();
    when(() => caches.shipyardShips).thenReturn(shipyardShips);

    final shipFuel = _MockShipFuel();
    // This ship uses fuel.
    const fuelCapacity = 1000;
    when(() => shipFuel.capacity).thenReturn(fuelCapacity);
    // And needs refueling.
    when(() => shipFuel.current).thenReturn(100);
    when(() => ship.fuel).thenReturn(shipFuel);
    const shipSymbol = ShipSymbol('S', 1);
    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');

    // We do not need to dock.
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn(start.waypoint);
    when(() => shipNav.systemSymbol).thenReturn(start.system);
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);
    // Needed by navigateShipAndLog to show time left.
    final shipNavRoute = _MockShipNavRoute();
    when(() => shipNav.route).thenReturn(shipNavRoute);
    final arrivalTime = DateTime(2022);
    when(() => shipNavRoute.arrival).thenReturn(arrivalTime);

    final shipEngine = _MockShipEngine();
    const shipSpeed = 10;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    when(() => ship.engine).thenReturn(shipEngine);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(start.waypoint);
    when(() => waypoint.systemSymbol).thenReturn(start.system);
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    // We have a marketplace.
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.MARKETPLACE,
        name: '',
        description: '',
      ),
    ]);
    registerFallbackValue(Duration.zero);
    when(
      () => marketPrices.hasRecentMarketData(
        start,
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: start.systemSymbol,
        maxJumps: 1,
      ),
    ).thenReturn([]);
    when(() => systemsCache.waypointFromSymbol(start)).thenReturn(
      SystemWaypoint(
        symbol: start.waypoint,
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );
    when(() => systemsCache.waypointFromSymbol(end)).thenReturn(
      SystemWaypoint(
        symbol: end.waypoint,
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          duration: 10,
        ),
      ],
      fuelCapacity: 10,
      fuelUsed: 10,
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
    );

    final market = Market(
      symbol: start.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
          tradeVolume: 10,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 10,
          sellPrice: 20,
        ),
        // Sells fuel so we can refuel.
        MarketTradeGood(
          symbol: TradeSymbol.FUEL.value,
          tradeVolume: 100,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 110,
        ),
      ],
    );
    when(() => marketCache.marketForSymbol(start))
        .thenAnswer((_) => Future.value(market));

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(10);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([
      ShipCargoItem(
        symbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
        name: '',
        description: '',
        units: 10,
      ),
    ]);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

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
            agent: agent,
            fuel: shipFuel,
            transaction: transaction,
          ),
        ),
      ),
    );
    when(() => systemsCache.waypointsInSystem(start.systemSymbol))
        .thenReturn([]);
    registerFallbackValue(start.systemSymbol);
    when(
      () => systemConnectivity.canJumpBetweenSystemSymbols(
        any(),
        any(),
      ),
    ).thenReturn(true);
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
            agent: agent,
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
            fuel: shipFuel,
            nav: shipNav..status = ShipNavStatus.IN_TRANSIT,
          ),
        ),
      ),
    );

    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(10);
    when(
      () => marketPrices.pricesFor(
        TradeSymbol.ADVANCED_CIRCUITRY,
        marketSymbol: any(named: 'marketSymbol'),
      ),
    ).thenReturn([
      MarketPrice(
        waypointSymbol: start,
        symbol: TradeSymbol.ADVANCED_CIRCUITRY,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 10,
        timestamp: DateTime(2021),
      ),
    ]);

    when(
      () => routePlanner.planRoute(
        start: any(named: 'start'),
        end: any(named: 'end'),
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(routePlan);
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
    verify(
      () => fleetApi.refuelShip(
        shipSymbol.symbol,
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    ).called(1);
    expect(waitUntil, arrivalTime);
  });

  test('trade contracts smoke test', () async {
    registerFallbackValue(Duration.zero);
    const shipSymbol = ShipSymbol('S', 1);

    final api = _MockApi();
    final db = _MockDatabase();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final shipyardPrices = _MockShipyardPrices();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final contractCache = _MockContractCache();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(true);
    when(() => centralCommand.expectedCreditsPerSecond(ship)).thenReturn(1);
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.contracts).thenReturn(contractCache);
    when(() => contractCache.activeContracts).thenReturn([]);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final shipCache = _MockShipCache();
    when(() => caches.ships).thenReturn(shipCache);
    final routePlanner = _MockRoutePlanner();
    when(() => caches.routePlanner).thenReturn(routePlanner);
    final contract = Contract(
      id: 'id',
      factionSymbol: 'factionSymbol',
      type: ContractTypeEnum.PROCUREMENT,
      expiration: DateTime(2021),
      terms: ContractTerms(
        deadline: DateTime(2021),
        payment: ContractPayment(onAccepted: 100, onFulfilled: 100),
      ),
    );
    final shipyardShips = _MockShipyardShipCache();
    when(() => caches.shipyardShips).thenReturn(shipyardShips);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

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
            contract: contract,
          ),
        ),
      ),
    );

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([]);

    when(() => ship.symbol).thenReturn(shipSymbol.symbol);
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-W');
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => ship.fuel).thenReturn(ShipFuel(capacity: 100, current: 100));
    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    registerFallbackValue(start);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn(start.waypoint);
    when(() => waypoint.systemSymbol).thenReturn(start.system);
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    final routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: start,
          endSymbol: end,
          type: RouteActionType.navCruise,
          duration: 10,
        ),
      ],
      fuelCapacity: 10,
      fuelUsed: 10,
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
    );
    when(
      () => centralCommand.findNextDeal(
        agentCache,
        contractCache,
        marketPrices,
        systemsCache,
        routePlanner,
        ship,
        maxWaypoints: any(named: 'maxWaypoints'),
        maxJumps: any(named: 'maxJumps'),
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenReturn(costedDeal);
    final state = BehaviorState(shipSymbol, Behavior.trader);

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
    expect(waitUntil, isNull);
  });

  test('handleUnwatedCargoIfNeeded smoke test', () async {
    final api = _MockApi();
    final db = _MockDatabase();
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
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
}
