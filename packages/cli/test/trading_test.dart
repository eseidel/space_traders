import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/market_scan.dart';
import 'package:cli/nav/route.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

class _MockMarketListingCache extends Mock implements MarketListingCache {}

class _MockMarketPrices extends Mock implements MarketPrices {}

class _MockRoutePlanner extends Mock implements RoutePlanner {}

class _MockShip extends Mock implements Ship {}

class _MockShipCargo extends Mock implements ShipCargo {}

class _MockShipEngine extends Mock implements ShipEngine {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockSystemConnectivity extends Mock implements SystemConnectivity {}

BuyOpp _makeBuyOpp({
  required WaypointSymbol marketSymbol,
  required TradeSymbol tradeSymbol,
  required int price,
}) {
  return BuyOpp(
    MarketPrice(
      waypointSymbol: marketSymbol,
      symbol: tradeSymbol,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: price,
      sellPrice: price + 1,
      tradeVolume: 10,
      timestamp: DateTime(2021),
      activity: ActivityLevel.WEAK,
    ),
  );
}

SellOpp _makeSellOpp({
  required WaypointSymbol marketSymbol,
  required TradeSymbol tradeSymbol,
  required int price,
}) {
  return SellOpp.fromMarketPrice(
    MarketPrice(
      waypointSymbol: marketSymbol,
      symbol: tradeSymbol,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: price - 1,
      sellPrice: price,
      tradeVolume: 10,
      timestamp: DateTime(2021),
      activity: ActivityLevel.WEAK,
    ),
  );
}

void main() {
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
    when(() => systemsCache.waypoint(start.waypointSymbol)).thenReturn(start);
    when(() => systemsCache.waypoint(end.waypointSymbol)).thenReturn(end);
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
            seconds: 15,
            fuelUsed: 10,
          ),
        ],
      ),
    );

    final deal = Deal.test(
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
      costPerAntimatterUnit: 10000,
    );

    expect(costed.expectedFuelCost, 100);
    expect(costed.cargoSize, 1);
    expect(costed.expectedTime.inSeconds, 15);
  });

  test('describeCostedDeal', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final costed = CostedDeal(
      deal: Deal.test(
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
            seconds: 10,
            fuelUsed: 0,
          ),
        ],
        fuelCapacity: 10,
        shipSpeed: 10,
      ),
      costPerFuelUnit: 100,
      costPerAntimatterUnit: 10000,
    );
    final profit = lightGreen.wrap('      +1c (100%)');
    expect(
      describeCostedDeal(costed),
      'ADVANCED_CIRCUITRY         A-B               '
      '1c -> A-C               2c $profit 10s   0c/s       1c',
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
    when(() => systemsCache.waypoint(saa.waypointSymbol)).thenReturn(saa);
    when(() => systemsCache.waypoint(sab.waypointSymbol)).thenReturn(sab);
    when(() => systemsCache.waypoint(sac.waypointSymbol)).thenReturn(sac);
    when(() => systemsCache.waypointsInSystem(saa.systemSymbol))
        .thenReturn(waypoints);
    const tradeSymbol = TradeSymbol.FUEL;
    final now = DateTime.timestamp();
    final prices = [
      MarketPrice(
        waypointSymbol: saa.waypointSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 200,
        sellPrice: 201,
        tradeVolume: 100,
        timestamp: now,
        activity: ActivityLevel.WEAK,
      ),
      MarketPrice(
        waypointSymbol: sab.waypointSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 100,
        sellPrice: 101,
        tradeVolume: 100,
        timestamp: now,
        activity: ActivityLevel.WEAK,
      ),
      MarketPrice(
        waypointSymbol: sac.waypointSymbol,
        symbol: tradeSymbol,
        supply: SupplyLevel.ABUNDANT,
        purchasePrice: 1000,
        sellPrice: 1001,
        tradeVolume: 100,
        timestamp: now,
        activity: ActivityLevel.WEAK,
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

    when(() => systemsCache[saa.systemSymbol]).thenReturn(
      System(
        symbol: 'S-A',
        sectorSymbol: 'S',
        x: 0,
        y: 0,
        type: SystemType.RED_STAR,
      ),
    );

    final systemConnectivity = _MockSystemConnectivity();
    final routePlanner = RoutePlanner.fromSystemsCache(
      systemsCache,
      systemConnectivity,
      sellsFuel: (_) => true,
    );

    final logger = _MockLogger();

    final marketScan = runWithLogger(
      logger,
      () => scanAllKnownMarkets(systemsCache, marketPrices),
    );

    final costed = runWithLogger(
      logger,
      () => findDealsFor(
        marketPrices,
        systemsCache,
        routePlanner,
        marketScan,
        maxTotalOutlay: 100000,
        startSymbol: ship.waypointSymbol,
        fuelCapacity: ship.fuel.capacity,
        cargoCapacity: ship.cargo.capacity,
        shipSpeed: ship.engine.speed,
      ).firstOrNull,
    );
    expect(costed, isNotNull);
    expect(costed!.expectedProfitPerSecond, 3);
    expect(costed.expectedProfit, 101);
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
      _makeBuyOpp(marketSymbol: a, tradeSymbol: trade1, price: 1),
    ];
    final sellOpps = [
      SellOpp.fromMarketPrice(
        MarketPrice(
          waypointSymbol: b,
          symbol: trade1,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
          tradeVolume: 10,
          timestamp: DateTime(2021),
          activity: ActivityLevel.WEAK,
        ),
      ),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 1);
    expect(deals.first.sourceSymbol, a);
    expect(deals.first.destinationSymbol, b);
    expect(deals.first.tradeSymbol, TradeSymbol.FUEL);
  });

  test('buildDealsFromScan extraSellOpps', () {
    const trade1 = TradeSymbol.FUEL;
    const trade2 = TradeSymbol.ICE_WATER;

    final a = WaypointSymbol.fromString('S-M-A');
    final b = WaypointSymbol.fromString('S-M-B');
    final c = WaypointSymbol.fromString('S-M-C');
    final buyOpps = [
      _makeBuyOpp(marketSymbol: a, tradeSymbol: trade1, price: 1),
      _makeBuyOpp(marketSymbol: a, tradeSymbol: trade2, price: 1),
    ];
    final sellOpps = [
      _makeSellOpp(marketSymbol: b, tradeSymbol: trade1, price: 2),
      _makeSellOpp(marketSymbol: b, tradeSymbol: trade2, price: 3),
    ];
    final scan = MarketScan.test(buyOpps: buyOpps, sellOpps: sellOpps);
    final deals = buildDealsFromScan(scan);
    expect(deals.length, 2);

    final extraSellOpps = [
      SellOpp.fromContract(
        waypointSymbol: c,
        tradeSymbol: trade2,
        price: 4,
        contractId: 'foo',
        maxUnits: 1,
      ),
    ];

    final deals2 = buildDealsFromScan(scan, extraSellOpps: extraSellOpps);
    // Importantly not 4.  extraSellOpps only applies to the second deal.
    expect(deals2.length, 3);
    // The contractId is plumbed through correctly.
    expect(deals2.any((d) => d.contractId == 'foo'), isTrue);
  });

  test('Deal.maxUnits', () {
    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    final deal = Deal(
      source: BuyOpp(
        MarketPrice(
          waypointSymbol: start,
          symbol: TradeSymbol.FUEL,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
          tradeVolume: 10,
          timestamp: DateTime(2021),
          activity: ActivityLevel.WEAK,
        ),
      ),
      destination: SellOpp.fromContract(
        waypointSymbol: end,
        tradeSymbol: TradeSymbol.FUEL,
        contractId: 'foo',
        price: 2,
        maxUnits: 10,
      ),
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
    expect(costedDeal.cargoSize, 100);
    expect(costedDeal.expectedUnits, 100);
    expect(costedDeal.maxUnitsToBuy, 10);
  });
  test('findBestMarketToBuy smoke test', () {
    final ship = _MockShip();
    final nearSymbol = WaypointSymbol.fromString('S-A-NEAR');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(nearSymbol.waypoint);
    const fuelCapacity = 100;
    when(() => ship.fuel)
        .thenReturn(ShipFuel(current: 100, capacity: fuelCapacity));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    const shipSpeed = 30;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    final routePlanner = _MockRoutePlanner();
    final marketPrices = _MockMarketPrices();
    final now = DateTime(2021);
    // 3 potential deals:
    // One which is the closest.  One which is further but better buy price,
    // and a 3rd which is further still but not worth the extra travel.
    final near = MarketPrice(
      waypointSymbol: nearSymbol,
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1000,
      sellPrice: 1,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );
    final mid = MarketPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-MID'),
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 100,
      sellPrice: 1,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );
    final far = MarketPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-FAR'),
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 10,
      sellPrice: 1,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );

    when(() => marketPrices.pricesFor(TradeSymbol.ALUMINUM))
        .thenReturn([near, mid, far]);

    RoutePlan fakePlan(WaypointSymbol start, WaypointSymbol end, int duration) {
      return RoutePlan(
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: duration,
            fuelUsed: 10,
          ),
        ],
      );
    }

    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: nearSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, nearSymbol, 1));
    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: mid.waypointSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, mid.waypointSymbol, 10));
    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: far.waypointSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, far.waypointSymbol, 10000000));

    final logger = _MockLogger();
    final market = runWithLogger(
      logger,
      () => findBestMarketToBuy(
        marketPrices,
        routePlanner,
        TradeSymbol.ALUMINUM,
        expectedCreditsPerSecond: 1,
        start: ship.waypointSymbol,
        fuelCapacity: ship.fuel.capacity,
        shipSpeed: ship.engine.speed,
      ),
    );

    expect(market?.price, mid);
  });

  test('findBestMarketToSell smoke test', () {
    final ship = _MockShip();
    when(() => ship.symbol).thenReturn('S-1');
    final nearSymbol = WaypointSymbol.fromString('S-A-NEAR');
    final midSymbol = WaypointSymbol.fromString('S-A-MID');
    final farSymbol = WaypointSymbol.fromString('S-A-FAR');
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.waypointSymbol).thenReturn(nearSymbol.waypoint);
    const fuelCapacity = 100;
    when(() => ship.fuel)
        .thenReturn(ShipFuel(current: 100, capacity: fuelCapacity));
    final shipEngine = _MockShipEngine();
    when(() => ship.engine).thenReturn(shipEngine);
    const shipSpeed = 30;
    when(() => shipEngine.speed).thenReturn(shipSpeed);
    final routePlanner = _MockRoutePlanner();
    final marketPrices = _MockMarketPrices();
    final now = DateTime(2021);
    // 3 potential deals:
    // One which is the closest.  One which is further but better sell price,
    // and a 3rd which is further still but not worth the extra travel.
    final near = MarketPrice(
      waypointSymbol: nearSymbol,
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 10,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );
    final mid = MarketPrice(
      waypointSymbol: midSymbol,
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 100,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );
    final far = MarketPrice(
      waypointSymbol: farSymbol,
      symbol: TradeSymbol.ALUMINUM,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 1000,
      tradeVolume: 10,
      timestamp: now,
      activity: ActivityLevel.WEAK,
    );

    when(() => marketPrices.pricesFor(TradeSymbol.ALUMINUM))
        .thenReturn([near, mid, far]);

    RoutePlan fakePlan(WaypointSymbol start, WaypointSymbol end, int duration) {
      return RoutePlan(
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
        actions: [
          RouteAction(
            startSymbol: start,
            endSymbol: end,
            type: RouteActionType.navCruise,
            seconds: duration,
            fuelUsed: 10,
          ),
        ],
      );
    }

    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: nearSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, nearSymbol, 1));
    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: midSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, midSymbol, 10));
    when(
      () => routePlanner.planRoute(
        start: nearSymbol,
        end: farSymbol,
        fuelCapacity: fuelCapacity,
        shipSpeed: shipSpeed,
      ),
    ).thenReturn(fakePlan(nearSymbol, farSymbol, 10000000));

    final marketListings = _MockMarketListingCache();
    MarketListing listing(WaypointSymbol symbol) {
      return MarketListing(
        waypointSymbol: symbol,
        exchange: const {TradeSymbol.ALUMINUM, TradeSymbol.FUEL},
      );
    }

    when(() => marketListings[nearSymbol]).thenReturn(listing(nearSymbol));
    when(() => marketListings[midSymbol]).thenReturn(listing(midSymbol));
    when(() => marketListings[farSymbol]).thenReturn(listing(farSymbol));

    final logger = _MockLogger();
    final market = runWithLogger(
      logger,
      () => findBestMarketToSell(
        marketPrices,
        marketListings,
        routePlanner,
        ship,
        TradeSymbol.ALUMINUM,
        expectedCreditsPerSecond: 1,
        unitsToSell: 1,
      ),
    );

    expect(market?.price, mid);
  });
  test('Deal.expectedUnits < cargoSize', () {
    // For high-value, low-tradeVolume items, we should expect their
    // prices to move (possibly quickly) and not be able to fill a full
    // cargo hold.

    final start = WaypointSymbol.fromString('S-A-B');
    final end = WaypointSymbol.fromString('S-A-C');
    const tradeSymbol = TradeSymbol.MODULE_CARGO_HOLD_I;
    final deal = Deal(
      source: BuyOpp(
        MarketPrice(
          waypointSymbol: start,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 10000,
          sellPrice: 10200,
          tradeVolume: 10,
          // If these aren't UTC, they won't roundtrip through JSON correctly
          // because MarketPrice always converts to UTC in toJson.
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
      destination: SellOpp.fromMarketPrice(
        MarketPrice(
          waypointSymbol: end,
          symbol: tradeSymbol,
          supply: SupplyLevel.ABUNDANT,
          purchasePrice: 10200,
          sellPrice: 10400,
          tradeVolume: 10,
          timestamp: DateTime(2021).toUtc(),
          activity: ActivityLevel.WEAK,
        ),
      ),
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
    expect(costedDeal.cargoSize, 100);
    expect(costedDeal.expectedUnits, 10);
  });
}
