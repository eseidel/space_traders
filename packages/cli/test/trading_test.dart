import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
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

class _MockMarketCache extends Mock implements MarketCache {}

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
      () => findDealForShip(
        marketPrices,
        systemsCache,
        systemConnectivity,
        marketScan,
        ship,
        maxJumps: 1,
        maxTotalOutlay: 100000,
      ),
    );
    expect(costed, isNotNull);
    expect(costed?.expectedProfitPerSecond, 3);
    expect(costed?.expectedProfit, 101);
  });
}
