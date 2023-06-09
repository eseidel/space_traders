import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockContractCache extends Mock implements ContractCache {}

class _MockContractsApi extends Mock implements ContractsApi {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceContractTrader smoke test', () async {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(BehaviorState('S', Behavior.trader));

    final api = _MockApi();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipyardPrices = _MockShipyardPrices();
    final contractCache = _MockContractCache();
    final jumpCache = JumpCache();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final centralCommand = _MockCentralCommand();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(false);
    when(
      () => centralCommand.findBetterTradeLocation(
        systemsCache,
        systemConnectivity,
        jumpCache,
        agentCache,
        contractCache,
        marketPrices,
        ship,
        maxJumps: any(named: 'maxJumps'),
        maxWaypoints: any(named: 'maxWaypoints'),
      ),
    ).thenAnswer((_) => Future.value());
    when(() => centralCommand.minTraderProfitPerSecond).thenReturn(10);
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.contracts).thenReturn(contractCache);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    when(() => caches.jumps).thenReturn(jumpCache);

    final shipFuel = _MockShipFuel();
    when(() => ship.fuel).thenReturn(shipFuel);
    when(() => shipFuel.capacity).thenReturn(0);
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-B');
    when(() => shipNav.systemSymbol).thenReturn('S-A');

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.MARKETPLACE,
        name: '',
        description: '',
      )
    ]);
    when(() => marketCache.marketForSymbol('S-A-B')).thenAnswer(
      (_) => Future.value(
        Market(
          symbol: 'S-A-B',
          tradeGoods: [
            MarketTradeGood(
              symbol: TradeSymbol.ADVANCED_CIRCUITRY.value,
              tradeVolume: 100,
              supply: MarketTradeGoodSupplyEnum.ABUNDANT,
              purchasePrice: 100,
              sellPrice: 101,
            )
          ],
        ),
      ),
    );
    when(
      () => marketPrices.hasRecentMarketData(
        'S-A-B',
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenReturn([]);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenReturn([]);

    when(() => centralCommand.getBehavior('S')).thenAnswer(
      (_) => BehaviorState('S', Behavior.trader),
    );

    when(
      () => centralCommand.disableBehaviorForShip(
        ship,
        Behavior.trader,
        any(),
        any(),
      ),
    ).thenAnswer((_) => Future.value());

    final costedDeal = CostedDeal(
      deal: const Deal(
        sourceSymbol: 'S-A-B',
        destinationSymbol: 'S-A-C',
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 20,
      ),
      tradeVolume: 10,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan(
        actions: [
          RouteAction(
            startSymbol: 'S-A-B',
            endSymbol: 'S-A-C',
            type: RouteActionType.navCruise,
            duration: 10,
          )
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
        systemConnectivity,
        jumpCache,
        ship,
        maxJumps: any(named: 'maxJumps'),
        maxWaypoints: any(named: 'maxWaypoints'),
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenAnswer((_) => Future.value(costedDeal));
    when(() => centralCommand.minTraderProfitPerSecond).thenReturn(10);
    when(
      () => centralCommand.visitLocalShipyard(
        api,
        shipyardPrices,
        agentCache,
        waypoint,
        ship,
      ),
    ).thenAnswer((_) => Future.value());
    when(() => centralCommand.setBehavior('S', any()))
        .thenAnswer((_) => Future.value());
    when(() => centralCommand.completeBehavior('S'))
        .thenAnswer((_) => Future.value());

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);
    when(() => shipCargo.inventory).thenReturn([]);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceTrader(
        api,
        centralCommand,
        caches,
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
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
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
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    final jumpCache = JumpCache();
    when(() => caches.jumps).thenReturn(jumpCache);

    final shipFuel = _MockShipFuel();
    // This ship uses fuel.
    when(() => shipFuel.capacity).thenReturn(1000);
    // And needs refueling.
    when(() => shipFuel.current).thenReturn(100);
    when(() => ship.fuel).thenReturn(shipFuel);
    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    // We do not need to dock.
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-B');
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => shipNav.flightMode).thenReturn(ShipNavFlightMode.CRUISE);

    final shipEngine = _MockShipEngine();
    when(() => shipEngine.speed).thenReturn(10);
    when(() => ship.engine).thenReturn(shipEngine);

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    // We have a marketplace.
    when(() => waypoint.traits).thenReturn([
      WaypointTrait(
        symbol: WaypointTraitSymbolEnum.MARKETPLACE,
        name: '',
        description: '',
      )
    ]);
    when(
      () => marketPrices.hasRecentMarketData(
        'S-A-B',
        maxAge: any(named: 'maxAge'),
      ),
    ).thenReturn(true);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenReturn([]);
    when(() => systemsCache.waypointFromSymbol('S-A-B')).thenReturn(
      SystemWaypoint(
        symbol: 'S-A-B',
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );
    when(() => systemsCache.waypointFromSymbol('S-A-C')).thenReturn(
      SystemWaypoint(
        symbol: 'S-A-C',
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );

    const routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: 'S-A-B',
          endSymbol: 'S-A-C',
          type: RouteActionType.navCruise,
          duration: 10,
        )
      ],
      fuelCapacity: 10,
      fuelUsed: 10,
      shipSpeed: 10,
    );
    final costedDeal = CostedDeal(
      deal: const Deal(
        sourceSymbol: 'S-A-B',
        destinationSymbol: 'S-A-C',
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 20,
      ),
      tradeVolume: 10,
      transactions: [],
      startTime: DateTime(2021),
      route: routePlan,
      costPerFuelUnit: 100,
    );

    final market = Market(
      symbol: 'S-A-B',
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
    when(() => marketCache.marketForSymbol('S-A-B'))
        .thenAnswer((_) => Future.value(market));

    when(() => centralCommand.getBehavior('S')).thenAnswer(
      (_) => BehaviorState('S', Behavior.trader, deal: costedDeal),
    );
    when(() => centralCommand.setRoutePlan(ship, routePlan))
        .thenAnswer((_) => Future.value());
    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehaviorForAll(
        ship,
        Behavior.trader,
        any(),
        any(),
      ),
    ).thenAnswer((_) => Future.value());

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
      )
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
      waypointSymbol: 'S-A-B',
      shipSymbol: 'S',
      timestamp: DateTime(2021),
    );
    when(
      () => fleetApi.refuelShip(
        'S',
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
    when(
      () => centralCommand.visitLocalShipyard(
        api,
        shipyardPrices,
        agentCache,
        waypoint,
        ship,
      ),
    ).thenAnswer((_) => Future.value());
    when(
      () => systemConnectivity.canJumpBetween(
        startSystemSymbol: any(named: 'startSystemSymbol'),
        endSystemSymbol: any(named: 'endSystemSymbol'),
      ),
    ).thenReturn(true);

    when(() => systemsCache.waypointsInSystem('S-A')).thenReturn([]);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceTrader(
        api,
        centralCommand,
        caches,
        ship,
        getNow: () => DateTime(2021),
      ),
    );
    verify(
      () => fleetApi.refuelShip(
        'S',
        refuelShipRequest: any(named: 'refuelShipRequest'),
      ),
    ).called(1);
    expect(waitUntil, isNull);
  });

  test('trade contracts smoke test', () async {
    registerFallbackValue(Duration.zero);
    registerFallbackValue(BehaviorState('S', Behavior.trader));

    final api = _MockApi();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipyardPrices = _MockShipyardPrices();
    final shipNav = _MockShipNav();
    final centralCommand = _MockCentralCommand();
    final contractCache = _MockContractCache();
    final jumpCache = JumpCache();
    when(() => centralCommand.isContractTradingEnabled).thenReturn(true);
    when(() => centralCommand.minTraderProfitPerSecond).thenReturn(10);
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);
    when(() => caches.contracts).thenReturn(contractCache);
    when(() => contractCache.activeContracts).thenReturn([]);
    when(() => caches.systemConnectivity).thenReturn(systemConnectivity);
    when(() => caches.jumps).thenReturn(jumpCache);
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
    when(() => contractCache.updateContract(contract)).thenAnswer(
      (_) => Future.value(),
    );

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

    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('W');
    when(() => shipNav.systemSymbol).thenReturn('S-A');

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);
    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));

    when(() => centralCommand.getBehavior('S'))
        .thenAnswer((_) => BehaviorState('S', Behavior.trader));
    when(() => centralCommand.setBehavior('S', any()))
        .thenAnswer((_) => Future.value());
    const routePlan = RoutePlan(
      actions: [
        RouteAction(
          startSymbol: 'S-A-B',
          endSymbol: 'A',
          type: RouteActionType.navCruise,
          duration: 10,
        )
      ],
      fuelCapacity: 10,
      fuelUsed: 10,
      shipSpeed: 10,
    );
    registerFallbackValue(routePlan);
    when(() => centralCommand.setRoutePlan(ship, any()))
        .thenAnswer((_) => Future.value());
    // when(() => centralCommand.disableBehaviorForShip(
    //       ship,
    //       Behavior.trader,
    //       any(),
    //       any(),
    //     )).thenAnswer((_) => Future.value());

    final costedDeal = CostedDeal(
      deal: const Deal(
        sourceSymbol: 'S-A-B',
        destinationSymbol: 'A',
        tradeSymbol: TradeSymbol.FUEL,
        purchasePrice: 10,
        sellPrice: 20,
      ),
      tradeVolume: 10,
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
        systemConnectivity,
        jumpCache,
        ship,
        maxWaypoints: any(named: 'maxWaypoints'),
        maxJumps: any(named: 'maxJumps'),
        maxTotalOutlay: any(named: 'maxTotalOutlay'),
      ),
    ).thenAnswer((_) => Future.value(costedDeal));
    when(
      () => centralCommand.disableBehaviorForShip(
        ship,
        Behavior.trader,
        any(),
        any(),
      ),
    ).thenAnswer((_) => Future.value());
    when(
      () => centralCommand.visitLocalShipyard(
        api,
        shipyardPrices,
        agentCache,
        waypoint,
        ship,
      ),
    ).thenAnswer((_) => Future.value());
    when(
      () => centralCommand.findBetterTradeLocation(
        systemsCache,
        systemConnectivity,
        jumpCache,
        agentCache,
        contractCache,
        marketPrices,
        ship,
        maxJumps: any(named: 'maxJumps'),
        maxWaypoints: any(named: 'maxWaypoints'),
      ),
    ).thenAnswer((_) => Future.value());

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceTrader(
        api,
        centralCommand,
        caches,
        ship,
      ),
    );
    expect(waitUntil, isNull);
  });
}
