import 'package:cli/api.dart';
import 'package:cli/cache/jump_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/transactions.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

void main() {
  test('estimateSellPrice null', () {
    final marketPrices = _MockMarketPrices();
    const a = TradeSymbol.FUEL;
    final estimate =
        estimateSellPrice(marketPrices, Market(symbol: 'S-S-A'), a);
    expect(estimate, null);
  });

  test('estimatePurchasePrice null', () {
    final marketPrices = _MockMarketPrices();
    const a = TradeSymbol.FUEL;
    final estimate =
        estimatePurchasePrice(marketPrices, Market(symbol: 'S-S-A'), a);
    expect(estimate, null);
  });

  test('estimatePrice fresh', () {
    final marketPrices = _MockMarketPrices();
    const a = TradeSymbol.FUEL;
    final market = Market(
      symbol: 'A',
      tradeGoods: [
        MarketTradeGood(
          symbol: a.value,
          tradeVolume: 100,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
        )
      ],
    );
    expect(
      estimateSellPrice(
        marketPrices,
        market,
        a,
      ),
      2,
    );
    expect(
      estimatePurchasePrice(
        marketPrices,
        market,
        a,
      ),
      1,
    );
  });

  test('Deal JSON roundtrip', () {
    final deal = Deal(
      sourceSymbol: WaypointSymbol.fromString('S-A-B'),
      destinationSymbol: WaypointSymbol.fromString('S-A-C'),
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final json = deal.toJson();
    final deal2 = Deal.fromJson(json);
    final json2 = deal2.toJson();
    expect(deal, deal2);
    expect(json, json2);
  });

  test('CostedDeal JSON roundtrip', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal(
      sourceSymbol: start,
      destinationSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
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

    final json = costed.toJson();
    final costed2 = CostedDeal.fromJson(json);
    final json2 = costed2.toJson();
    // Can't compare objects via equals because CostedDeal is not immutable.
    expect(json, json2);
  });

  test('costOutDeal basic', () {
    final systemsCache = _MockSystemsCache();
    final start = SystemWaypoint(
      symbol: 'X-S-A',
      type: WaypointType.ASTEROID_FIELD,
      x: 0,
      y: 0,
    );
    final end = SystemWaypoint(
      symbol: 'X-S-B',
      type: WaypointType.PLANET,
      x: 0,
      y: 0,
    );
    when(() => systemsCache.waypointFromSymbol(start.waypointSymbol))
        .thenReturn(start);
    when(() => systemsCache.waypointFromSymbol(end.waypointSymbol))
        .thenReturn(end);
    when(() => systemsCache.waypointsInSystem(start.systemSymbol))
        .thenReturn([start, end]);

    final routePlanner = _MockRoutePlanner();
    const fuelCapacity = 100;
    const shipSpeed = 1;
    registerFallbackValue(start.waypointSymbol);
    when(
      () => routePlanner.planRoute(
        start: any(named: 'start'),
        end: any(named: 'end'),
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(
      RoutePlan(
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
        actions: [
          RouteAction(
            startSymbol: start.waypointSymbol,
            endSymbol: end.waypointSymbol,
            type: RouteActionType.navCruise,
            duration: 15,
          )
        ],
        fuelUsed: 0,
      ),
    );

    final deal = Deal(
      sourceSymbol: start.waypointSymbol,
      destinationSymbol: end.waypointSymbol,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = costOutDeal(
      systemsCache,
      routePlanner,
      deal,
      cargoSize: 1,
      shipSpeed: shipSpeed,
      shipFuelCapacity: fuelCapacity,
      shipWaypointSymbol: start.waypointSymbol,
      costPerFuelUnit: 100,
    );

    expect(costed.expectedFuelCost, 0);
    expect(costed.cargoSize, 1);
    expect(costed.expectedTime.inSeconds, 15);
  });

  test('describe deal', () {
    final deal = Deal(
      sourceSymbol: WaypointSymbol.fromString('S-A-B'),
      destinationSymbol: WaypointSymbol.fromString('S-A-C'),
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    // Not clear why we have two of similar functions here.
    final profit1 = lightGreen.wrap('   +1c (100%)');
    expect(
      describeDeal(deal),
      'FUEL                S-A-B     1c -> S-A-C     2c $profit1',
    );
    final profit2 = lightGreen.wrap('+1c');
    expect(
      dealDescription(deal),
      'Deal ($profit2): FUEL 1c @ S-A-B -> 2c @ S-A-C profit: 1c per unit ',
    );
  });

  test('describeCostedDeal', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final costed = CostedDeal(
      deal: Deal(
        sourceSymbol: start,
        destinationSymbol: end,
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 1,
        sellPrice: 2,
      ),
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            duration: 10,
          )
        ],
        fuelCapacity: 10,
        fuelUsed: 0,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
    );
    final profit = lightGreen.wrap('     +1c (100%)');
    expect(
      describeCostedDeal(costed),
      'ADVANCED_CIRCUITRY         S-A-B                '
      '1c -> S-A-C                2c $profit 10s 0c/s 1c',
    );
  });

  test('findDealFor includes time to source', () async {
    // findDealFor used to not consider time to get to the source system.
    // which meant if there was a very far away system with a great deal
    // we would try to do that, even if it took forever to get there and thus
    // the profit per second was poor.
    // S-A-A and S-A-B are close but have poor deals, S-A-C is far away but
    // has a great deal, but we still choose S-A-B because it's faster and
    // thus has a better profit per second.
    final marketPrices = _MockMarketPrices();
    final systemsCache = _MockSystemsCache();
    final saa = SystemWaypoint(
      symbol: 'S-A-A',
      type: WaypointType.ASTEROID_FIELD,
      x: 0,
      y: 0,
    );
    final sab = SystemWaypoint(
      symbol: 'S-A-B',
      type: WaypointType.ASTEROID_FIELD,
      x: 0,
      y: 0,
    );
    final sac = SystemWaypoint(
      symbol: 'S-A-C',
      type: WaypointType.ASTEROID_FIELD,
      x: 1000,
      y: 1000,
    );
    final waypoints = [saa, sab, sac];
    when(() => systemsCache.waypointFromSymbol(saa.waypointSymbol))
        .thenReturn(saa);
    when(() => systemsCache.waypointFromSymbol(sab.waypointSymbol))
        .thenReturn(sab);
    when(() => systemsCache.waypointFromSymbol(sac.waypointSymbol))
        .thenReturn(sac);
    when(() => systemsCache.waypointsInSystem(saa.systemSymbol))
        .thenReturn(waypoints);
    when(
      () => systemsCache.waypointSymbolsInJumpRadius(
        startSystem: saa.systemSymbol,
        maxJumps: 1,
      ),
    ).thenAnswer((invocation) => waypoints.map((w) => w.waypointSymbol));
    final tradeSymbol = TradeSymbol.FUEL.value;
    final now = DateTime.timestamp();
    final prices = [
      MarketPrice(
        waypointSymbol: saa.waypointSymbol,
        symbol: tradeSymbol,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 200,
        sellPrice: 201,
        tradeVolume: 100,
        timestamp: now,
      ),
      MarketPrice(
        waypointSymbol: sab.waypointSymbol,
        symbol: tradeSymbol,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 100,
        timestamp: now,
      ),
      MarketPrice(
        waypointSymbol: sac.waypointSymbol,
        symbol: tradeSymbol,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 1000,
        sellPrice: 1001,
        tradeVolume: 100,
        timestamp: now,
      ),
    ];
    when(() => marketPrices.prices).thenReturn(prices);
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final shipEngine = _MockShipEngine();
    final shipCargo = _MockShipCargo();
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-A');
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipEngine.speed).thenReturn(30);
    when(() => ship.cargo).thenReturn(shipCargo);
    when(() => shipCargo.capacity).thenReturn(1);
    when(() => shipCargo.units).thenReturn(0);

    final systemConnectivity = _MockSystemConnectivity();
    final jumpCache = JumpCache();
    registerFallbackValue(SystemSymbol.fromString('S-A'));
    when(
      () => systemConnectivity.canJumpBetweenSystemSymbols(
        any(),
        any(),
      ),
    ).thenReturn(true);
    when(() => systemsCache.systemBySymbol(saa.systemSymbol)).thenReturn(
      System(
        symbol: 'S-A',
        sectorSymbol: 'S',
        x: 0,
        y: 0,
        type: SystemType.RED_STAR,
      ),
    );

    final routePlanner = RoutePlanner(
      systemConnectivity: systemConnectivity,
      jumpCache: jumpCache,
      systemsCache: systemsCache,
    );

    final logger = _MockLogger();

    const maxJumps = 1;
    const maxWaypoints = 10;
    final marketScan = runWithLogger(
      logger,
      () => scanNearbyMarkets(
        systemsCache,
        marketPrices,
        systemSymbol: ship.systemSymbol,
        maxJumps: maxJumps,
        maxWaypoints: maxWaypoints,
      ),
    );

    final costed = await runWithLogger(
      logger,
      () => findDealFor(
        marketPrices,
        systemsCache,
        routePlanner,
        marketScan,
        maxJumps: 1,
        maxTotalOutlay: 100000,
        startSymbol: ship.waypointSymbol,
        fuelCapacity: ship.fuel.capacity,
        cargoCapacity: ship.cargo.capacity,
        shipSpeed: ship.engine.speed,
      ),
    );
    expect(costed, isNotNull);
    expect(costed?.expectedProfitPerSecond, 3);
    expect(costed?.expectedProfit, 101);
  });

  test('buildDealsFromScan empty', () {
    final scan = MarketScan.test(buyOpps: [], sellOpps: []);
    final deals = buildDealsFromScan(scan);
    expect(deals, isEmpty);
  });

  test('buildDealsFromScan one', () {
    const trade1 = TradeSymbol.FUEL;
    final a = WaypointSymbol.fromString('S-M-A');
    final b = WaypointSymbol.fromString('S-M-B');
    final buyOpps = [
      BuyOpp(marketSymbol: a, tradeSymbol: trade1, price: 1),
    ];
    final sellOpps = [
      SellOpp(marketSymbol: b, tradeSymbol: trade1, price: 2),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 1);
    expect(deals.first.sourceSymbol, a);
    expect(deals.first.destinationSymbol, b);
    expect(deals.first.tradeSymbol, TradeSymbol.FUEL);
    expect(deals.first.purchasePrice, 1);
    expect(deals.first.sellPrice, 2);
  });

  test('buildDealsFromScan extraSellOpps', () {
    const trade1 = TradeSymbol.FUEL;
    const trade2 = TradeSymbol.ICE_WATER;

    final a = WaypointSymbol.fromString('S-M-A');
    final b = WaypointSymbol.fromString('S-M-B');
    final c = WaypointSymbol.fromString('S-M-C');
    final buyOpps = [
      BuyOpp(marketSymbol: a, tradeSymbol: trade1, price: 1),
      BuyOpp(marketSymbol: a, tradeSymbol: trade2, price: 1),
    ];
    final sellOpps = [
      SellOpp(marketSymbol: b, tradeSymbol: trade1, price: 2),
      SellOpp(marketSymbol: b, tradeSymbol: trade2, price: 3),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 2);

    final extraSellOpps = [
      SellOpp(
        marketSymbol: c,
        tradeSymbol: trade2,
        price: 4,
        contractId: 'foo',
      ),
    ];

    final deals2 = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);
    // Importantly not 4.  extraSellOpps only applies to the second deal.
    expect(deals2.length, 3);
    // The contractId is plumbed through correctly.
    expect(deals2.any((d) => d.contractId == 'foo'), isTrue);
  });

  test('byAddingTransactions', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal(
      sourceSymbol: start,
      destinationSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
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
    const shipSymbol = ShipSymbol('S', 1);
    final transaction1 = Transaction(
      shipSymbol: shipSymbol,
      waypointSymbol: start,
      tradeSymbol: 'FUEL',
      perUnitPrice: 10,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      quantity: 1,
      timestamp: DateTime(2021),
      agentCredits: 10,
      accounting: AccountingType.fuel,
    );
    final transaction2 = Transaction(
      shipSymbol: shipSymbol,
      waypointSymbol: end,
      tradeSymbol: 'FUEL',
      perUnitPrice: 10,
      tradeType: MarketTransactionTypeEnum.SELL,
      quantity: 1,
      timestamp: DateTime(2021),
      agentCredits: 10,
      accounting: AccountingType.fuel,
    );
    final costed2 = costed.byAddingTransactions([transaction1]);
    expect(costed2.transactions, [transaction1]);
    final costed3 = costed2.byAddingTransactions([transaction2]);
    expect(costed3.transactions, [transaction1, transaction2]);
  });

  test('Deal.maxUnits', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal(
      sourceSymbol: start,
      destinationSymbol: end,
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
      maxUnits: 10,
    );
    final costedDeal = CostedDeal(
      deal: deal,
      cargoSize: 100,
      transactions: [],
      startTime: DateTime(2021),
      route: RoutePlan(
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
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
    expect(costedDeal.cargoSize, 100);
    expect(costedDeal.expectedUnits, 100);
    expect(costedDeal.maxUnitsToBuy, 10);
  });
}
