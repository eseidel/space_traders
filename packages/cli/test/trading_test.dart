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

void main() {
  test('estimateSellPrice null', () {
    final marketPrices = _MockMarketPrices();
    final estimate =
        estimateSellPrice(marketPrices, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePurchasePrice null', () {
    final marketPrices = _MockMarketPrices();
    final estimate =
        estimatePurchasePrice(marketPrices, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePrice fresh', () {
    final marketPrices = _MockMarketPrices();
    final market = Market(
      symbol: 'A',
      tradeGoods: [
        MarketTradeGood(
          symbol: 'FUEL',
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
        'FUEL',
      ),
      2,
    );
    expect(
      estimatePurchasePrice(
        marketPrices,
        market,
        'FUEL',
      ),
      1,
    );
  });

  test('Deal JSON roundtrip', () {
    const deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
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
    const deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan(
        actions: [
          RouteAction(
            startSymbol: 'A',
            endSymbol: 'B',
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
    final systemConnectivity = _MockSystemConnectivity();
    final jumpCache = JumpCache();
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
    when(() => systemsCache.waypointFromSymbol('X-S-A')).thenReturn(start);
    when(() => systemsCache.waypointFromSymbol('X-S-B')).thenReturn(end);
    when(() => systemsCache.waypointsInSystem('X-S')).thenReturn([start, end]);
    when(
      () => systemConnectivity.canJumpBetweenSystemSymbols(
        any(),
        any(),
      ),
    ).thenReturn(true);

    const deal = Deal(
      sourceSymbol: 'X-S-A',
      destinationSymbol: 'X-S-B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = costOutDeal(
      systemsCache,
      systemConnectivity,
      jumpCache,
      deal,
      cargoSize: 1,
      shipSpeed: 1,
      shipFuelCapacity: 100,
      shipWaypointSymbol: 'X-S-A',
      costPerFuelUnit: 100,
    );

    /// These aren't very useful numbers, I don't think it takes 15s to fly
    /// 0 distance (even between orbitals)?
    expect(costed.expectedFuelCost, 0);
    expect(costed.cargoSize, 1);
    expect(costed.expectedTime, 15);
  });

  test('describe deal', () {
    const deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    // Not clear why we have two of similar functions here.
    final profit1 = lightGreen.wrap('   +1c (100%)');
    expect(
      describeDeal(deal),
      'FUEL                A     1c -> B     2c $profit1',
    );
    final profit2 = lightGreen.wrap('+1c');
    expect(
      dealDescription(deal),
      'Deal ($profit2): FUEL 1c @ A -> 2c @ B profit: 1c per unit ',
    );
  });

  test('describeCostedDeal', () {
    final costed = CostedDeal(
      deal: const Deal(
        sourceSymbol: 'A',
        destinationSymbol: 'B',
        tradeSymbol: TradeSymbol.ADVANCED_CIRCUITRY,
        purchasePrice: 1,
        sellPrice: 2,
      ),
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan(
        actions: [
          RouteAction(
            startSymbol: 'A',
            endSymbol: 'B',
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
      'ADVANCED_CIRCUITRY         A                    '
      '1c -> B                    2c $profit 10s 0c/s 1c',
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
    final systemConnectivity = _MockSystemConnectivity();
    final jumpCache = JumpCache();
    when(
      () => systemConnectivity.canJumpBetweenSystemSymbols(
        any(),
        any(),
      ),
    ).thenReturn(true);
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
    when(() => systemsCache.waypointFromSymbol('S-A-A')).thenReturn(saa);
    when(() => systemsCache.waypointFromSymbol('S-A-B')).thenReturn(sab);
    when(() => systemsCache.waypointFromSymbol('S-A-C')).thenReturn(sac);
    when(() => systemsCache.waypointsInSystem('S-A')).thenReturn(waypoints);
    when(
      () => systemsCache.waypointSymbolsInJumpRadius(
        startSystem: 'S-A',
        maxJumps: 1,
      ),
    ).thenAnswer((invocation) => ['S-A-A', 'S-A-B', 'S-A-C']);
    final tradeSymbol = TradeSymbol.FUEL.value;
    final now = DateTime.timestamp();
    final prices = [
      MarketPrice(
        waypointSymbol: 'S-A-A',
        symbol: tradeSymbol,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 200,
        sellPrice: 201,
        tradeVolume: 100,
        timestamp: now,
      ),
      MarketPrice(
        waypointSymbol: 'S-A-B',
        symbol: tradeSymbol,
        supply: MarketTradeGoodSupplyEnum.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 100,
        timestamp: now,
      ),
      MarketPrice(
        waypointSymbol: 'S-A-C',
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

    final logger = _MockLogger();

    const maxJumps = 1;
    const maxWaypoints = 10;
    final marketScan = runWithLogger(
      logger,
      () => scanNearbyMarkets(
        systemsCache,
        marketPrices,
        systemSymbol: ship.nav.systemSymbol,
        maxJumps: maxJumps,
        maxWaypoints: maxWaypoints,
      ),
    );

    final costed = await runWithLogger(
      logger,
      () => findDealFor(
        marketPrices,
        systemsCache,
        systemConnectivity,
        jumpCache,
        marketScan,
        maxJumps: 1,
        maxTotalOutlay: 100000,
        startSymbol: ship.nav.waypointSymbol,
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
    final trade1 = TradeSymbol.FUEL.value;
    final buyOpps = [
      BuyOpp(marketSymbol: 'M-A', tradeSymbol: trade1, price: 1),
    ];
    final sellOpps = [
      SellOpp(marketSymbol: 'M-B', tradeSymbol: trade1, price: 2),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 1);
    expect(deals.first.sourceSymbol, 'M-A');
    expect(deals.first.destinationSymbol, 'M-B');
    expect(deals.first.tradeSymbol, TradeSymbol.FUEL);
    expect(deals.first.purchasePrice, 1);
    expect(deals.first.sellPrice, 2);
  });

  test('buildDealsFromScan extraSellOpps', () {
    final trade1 = TradeSymbol.FUEL.value;
    final trade2 = TradeSymbol.ICE_WATER.value;

    final buyOpps = [
      BuyOpp(marketSymbol: 'M-A', tradeSymbol: trade1, price: 1),
      BuyOpp(marketSymbol: 'M-A', tradeSymbol: trade2, price: 1),
    ];
    final sellOpps = [
      SellOpp(marketSymbol: 'M-B', tradeSymbol: trade1, price: 2),
      SellOpp(marketSymbol: 'M-B', tradeSymbol: trade2, price: 3),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 2);

    final extraSellOpps = [
      SellOpp(
        marketSymbol: 'M-C',
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
    const deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = CostedDeal(
      deal: deal,
      cargoSize: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan(
        actions: [
          RouteAction(
            startSymbol: 'A',
            endSymbol: 'B',
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
    final transaction1 = Transaction(
      shipSymbol: 'foo',
      waypointSymbol: 'bar',
      tradeSymbol: 'FUEL',
      perUnitPrice: 10,
      tradeType: MarketTransactionTypeEnum.PURCHASE,
      quantity: 1,
      timestamp: DateTime(2021),
      agentCredits: 10,
      accounting: AccountingType.fuel,
    );
    final transaction2 = Transaction(
      shipSymbol: 'foo',
      waypointSymbol: 'bar',
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
    const deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
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
      route: const RoutePlan(
        actions: [
          RouteAction(
            startSymbol: 'A',
            endSymbol: 'B',
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
