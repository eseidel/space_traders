import 'package:cli/behavior/behavior.dart';
import 'package:cli/behavior/central_command.dart';
import 'package:cli/behavior/trader.dart';
import 'package:cli/cache/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockAgent extends Mock implements Agent {}

class _MockAgentCache extends Mock implements AgentCache {}

class _MockApi extends Mock implements Api {}

class _MockCaches extends Mock implements Caches {}

class _MockCentralCommand extends Mock implements CentralCommand {}

class _MockFleetApi extends Mock implements FleetApi {}

class _MockLogger extends Mock implements Logger {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipFuel extends Mock implements ShipFuel {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockShipyardPrices extends Mock implements ShipyardPrices {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockTransactionLog extends Mock implements TransactionLog {}

class _MockWaypoint extends Mock implements Waypoint {}

class _MockWaypointCache extends Mock implements WaypointCache {}

void main() {
  test('advanceContractTrader smoke test', () async {
    final api = _MockApi();
    final marketPrices = _MockMarketPrices();
    final agentCache = _MockAgentCache();
    final ship = _MockShip();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final transactionLog = _MockTransactionLog();
    final shipyardPrices = _MockShipyardPrices();
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);
    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);

    when(() => ship.symbol).thenReturn('S');
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.status).thenReturn(ShipNavStatus.DOCKED);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-B');
    when(() => shipNav.systemSymbol).thenReturn('S-A');

    final waypoint = _MockWaypoint();
    when(() => waypoint.symbol).thenReturn('S-A-B');
    when(() => waypoint.systemSymbol).thenReturn('S-A');
    when(() => waypoint.type).thenReturn(WaypointType.PLANET);
    when(() => waypoint.traits).thenReturn([]);

    when(() => waypointCache.waypoint(any()))
        .thenAnswer((_) => Future.value(waypoint));
    when(
      () => systemsCache.systemSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenReturn([]);

    when(() => centralCommand.getBehavior('S')).thenAnswer(
      (_) => BehaviorState('S', Behavior.arbitrageTrader),
    );
    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehavior(
        ship,
        Behavior.arbitrageTrader,
        any(),
        any(),
      ),
    ).thenAnswer((_) => Future.value());

    when(
      () => centralCommand.findNextDeal(
        marketPrices,
        systemsCache,
        waypointCache,
        marketCache,
        ship,
        maxJumps: any(named: 'maxJumps'),
        maxOutlay: any(named: 'maxOutlay'),
        availableSpace: any(named: 'availableSpace'),
      ),
    ).thenAnswer((_) => Future.value());

    final shipCargo = _MockShipCargo();
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.units).thenReturn(0);
    when(() => shipCargo.capacity).thenReturn(10);

    final agent = _MockAgent();
    when(() => agentCache.agent).thenReturn(agent);
    when(() => agent.credits).thenReturn(1000000);

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceArbitrageTrader(
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
    final shipNav = _MockShipNav();
    final fleetApi = _MockFleetApi();
    when(() => api.fleet).thenReturn(fleetApi);

    final centralCommand = _MockCentralCommand();
    final caches = _MockCaches();
    when(() => caches.waypoints).thenReturn(waypointCache);
    when(() => caches.markets).thenReturn(marketCache);
    when(() => caches.transactions).thenReturn(transactionLog);
    when(() => caches.marketPrices).thenReturn(marketPrices);
    when(() => caches.agent).thenReturn(agentCache);
    when(() => caches.systems).thenReturn(systemsCache);
    when(() => caches.shipyardPrices).thenReturn(shipyardPrices);

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

    final costedDeal = CostedDeal(
      deal: const Deal(
        sourceSymbol: 'S-A-B',
        destinationSymbol: 'S-A-C',
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 10,
        sellPrice: 20,
      ),
      fuelCost: 0,
      tradeVolume: 10,
      time: 10,
      transactions: [],
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
      (_) => BehaviorState('S', Behavior.arbitrageTrader, deal: costedDeal),
    );
    when(() => centralCommand.setDestination(ship, 'S-A-C'))
        .thenAnswer((_) => Future.value());
    registerFallbackValue(Duration.zero);
    when(
      () => centralCommand.disableBehavior(
        ship,
        Behavior.arbitrageTrader,
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

    final logger = _MockLogger();
    final waitUntil = await runWithLogger(
      logger,
      () => advanceArbitrageTrader(
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
}