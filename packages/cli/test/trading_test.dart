import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

void main() {
  test('MarketScan empty', () {
    final marketPrices = _MockMarketPrices();
    final scan = MarketScan.fromMarkets(marketPrices, []);
    final deals = buildDealsFromScan(scan);
    expect(deals, isEmpty);
  });

  test('MarketScan single deal', () {
    final marketPrices = _MockMarketPrices();
    final tradeGood =
        TradeGood(symbol: TradeSymbol.FUEL, name: 'Fuel', description: '');
    final markets = [
      Market(
        symbol: 'A',
        exchange: [tradeGood],
        tradeGoods: [
          MarketTradeGood(
            symbol: 'FUEL',
            tradeVolume: 100,
            supply: MarketTradeGoodSupplyEnum.ABUNDANT,
            purchasePrice: 2,
            sellPrice: 3,
          )
        ],
      ),
      Market(
        symbol: 'B',
        exchange: [tradeGood],
        tradeGoods: [
          MarketTradeGood(
            symbol: 'FUEL',
            tradeVolume: 100,
            supply: MarketTradeGoodSupplyEnum.ABUNDANT,
            purchasePrice: 1,
            sellPrice: 2,
          )
        ],
      ),
    ];
    final scan = MarketScan.fromMarkets(marketPrices, markets);
    final deals = buildDealsFromScan(scan);
    expect(deals, isNotEmpty);
  });

  test('MarketScan topLimit', () {
    // We're testing that market scan compares the top N sell/buy deals.
    // There was a bug before where it was sorting the sell opps in the wrong
    // direction, thus always returning the 10 worst sell locations rather
    // than the 10 best.

    final marketPrices = _MockMarketPrices();
    final tradeGood =
        TradeGood(symbol: TradeSymbol.FUEL, name: 'Fuel', description: '');
    final markets = [
      for (int i = 0; i < 10; i++)
        Market(
          symbol: '$i',
          exchange: [tradeGood],
          tradeGoods: [
            MarketTradeGood(
              symbol: 'FUEL',
              tradeVolume: 100,
              supply: MarketTradeGoodSupplyEnum.ABUNDANT,
              purchasePrice: 100,
              sellPrice: 101,
            )
          ],
        ),
      Market(
        symbol: 'EXPENSIVE',
        exchange: [tradeGood],
        tradeGoods: [
          MarketTradeGood(
            symbol: 'FUEL',
            tradeVolume: 100,
            supply: MarketTradeGoodSupplyEnum.ABUNDANT,
            purchasePrice: 200,
            sellPrice: 201,
          )
        ],
      ),
      Market(
        symbol: 'CHEAP',
        exchange: [tradeGood],
        tradeGoods: [
          MarketTradeGood(
            symbol: 'FUEL',
            tradeVolume: 100,
            supply: MarketTradeGoodSupplyEnum.ABUNDANT,
            purchasePrice: 10,
            sellPrice: 11,
          )
        ],
      ),
    ];
    final scan = MarketScan.fromMarkets(marketPrices, markets, topLimit: 10);
    final buyOpps = scan.buyOppsForTradeSymbol('FUEL');
    expect(buyOpps, hasLength(10));
    final buyPrices = buyOpps.map((o) => o.price).toList();
    expect(buyPrices, [10, 100, 100, 100, 100, 100, 100, 100, 100, 100]);
    final sellOpps = scan.sellOppsForTradeSymbol('FUEL');
    expect(sellOpps, hasLength(10));
    final sellPrices = sellOpps.map((o) => o.price).toList();
    expect(sellPrices, [201, 101, 101, 101, 101, 101, 101, 101, 101, 101]);
  });

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
      tradeVolume: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan.empty(fuelCapacity: 10, shipSpeed: 10),
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
      () => systemConnectivity.canJumpBetween(
        startSystemSymbol: any(named: 'startSystemSymbol'),
        endSystemSymbol: any(named: 'endSystemSymbol'),
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
    expect(costed.tradeVolume, 1);
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
        tradeSymbol: TradeSymbol.FUEL,
        purchasePrice: 1,
        sellPrice: 2,
      ),
      tradeVolume: 1,
      transactions: [],
      startTime: DateTime(2021),
      route: const RoutePlan.empty(fuelCapacity: 10, shipSpeed: 10),
      costPerFuelUnit: 100,
    );
    final profit = lightGreen.wrap('     +1c (100%)');
    expect(
      describeCostedDeal(costed),
      'FUEL                       A       1c -> B       2c $profit 0s 1c/s 1c',
    );
  });

  test('findDealFor no markets', () async {
    final marketPrices = _MockMarketPrices();
    final systemsCache = _MockSystemsCache();
    final systemConnectivity = _MockSystemConnectivity();
    final marketCache = _MockMarketCache();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => marketCache.marketsInJumpRadius(startSystem: 'S-A', maxJumps: 1))
        .thenAnswer((_) => const Stream.empty());

    // We should use a MarketScan mock here.
    const maxJumps = 1;
    final marketScan = await scanMarketsNear(
      marketCache,
      marketPrices,
      systemSymbol: ship.nav.systemSymbol,
      maxJumps: maxJumps,
    );

    final logger = _MockLogger();
    final costed = await runWithLogger(
      logger,
      () => findDealFor(
        marketPrices,
        systemsCache,
        systemConnectivity,
        marketScan,
        ship,
        maxJumps: maxJumps,
        maxTotalOutlay: 100000,
        availableSpace: 10,
      ),
    );
    expect(costed, isNull);
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
    when(
      () => systemConnectivity.canJumpBetween(
        startSystemSymbol: any(named: 'startSystemSymbol'),
        endSystemSymbol: any(named: 'endSystemSymbol'),
      ),
    ).thenReturn(true);
    final marketCache = _MockMarketCache();
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
    final tradeGood =
        TradeGood(symbol: TradeSymbol.FUEL, name: 'Fuel', description: '');
    final marketA = Market(
      symbol: 'S-A-A',
      exchange: [tradeGood],
      tradeGoods: [
        MarketTradeGood(
          symbol: 'FUEL',
          tradeVolume: 100,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 200,
          sellPrice: 201,
        )
      ],
    );
    final marketB = Market(
      symbol: 'S-A-B',
      exchange: [tradeGood],
      tradeGoods: [
        MarketTradeGood(
          symbol: 'FUEL',
          tradeVolume: 100,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 100,
          sellPrice: 101,
        )
      ],
    );
    final marketC = Market(
      symbol: 'S-A-C',
      exchange: [tradeGood],
      tradeGoods: [
        MarketTradeGood(
          symbol: 'FUEL',
          tradeVolume: 100,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 1000,
          sellPrice: 1001,
        )
      ],
    );
    final markets = [marketA, marketB, marketC];
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    final shipEngine = _MockShipEngine();
    when(() => ship.fuel).thenReturn(ShipFuel(current: 100, capacity: 100));
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn('S-A-A');
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => ship.engine).thenReturn(shipEngine);
    when(() => shipEngine.speed).thenReturn(30);
    when(() => marketCache.marketsInJumpRadius(startSystem: 'S-A', maxJumps: 1))
        .thenAnswer((_) => Stream.fromIterable(markets));

    // We should use a MarketScan mock here.
    const maxJumps = 1;
    final marketScan = await scanMarketsNear(
      marketCache,
      marketPrices,
      systemSymbol: ship.nav.systemSymbol,
      maxJumps: maxJumps,
    );

    final logger = _MockLogger();
    final costed = await runWithLogger(
      logger,
      () => findDealFor(
        marketPrices,
        systemsCache,
        systemConnectivity,
        marketScan,
        ship,
        maxJumps: 1,
        maxTotalOutlay: 100000,
        availableSpace: 1,
      ),
    );
    expect(costed, isNotNull);
    expect(costed?.expectedProfitPerSecond, 3);
    expect(costed?.expectedProfit, 101);
  });
}
