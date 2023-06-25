import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/trading.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _MockShipNav extends Mock implements ShipNav {}

class _MockSystemsCache extends Mock implements SystemsCache {}

class _MockMarketCache extends Mock implements MarketCache {}

class _MockWaypointCache extends Mock implements WaypointCache {}

class _MockPriceData extends Mock implements MarketPrices {}

class _MockShip extends Mock implements Ship {}

void main() {
  test('MarketScan empty', () {
    final marketPrices = _MockPriceData();
    final scan = MarketScan.fromMarkets(marketPrices, []);
    final deals = buildDealsFromScan(scan);
    expect(deals, isEmpty);
  });

  test('MarketScan single deal', () {
    final marketPrices = _MockPriceData();
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

  test('estimateSellPrice null', () {
    final marketPrices = _MockPriceData();
    final estimate =
        estimateSellPrice(marketPrices, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePurchasePrice null', () {
    final marketPrices = _MockPriceData();
    final estimate =
        estimatePurchasePrice(marketPrices, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePrice fresh', () {
    final marketPrices = _MockPriceData();
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
      fuelCost: 1,
      tradeVolume: 1,
      time: 1,
    );

    final json = costed.toJson();
    final costed2 = CostedDeal.fromJson(json);
    final json2 = costed2.toJson();
    // Can't compare objects via equals because CostedDeal is not immutable.
    expect(json, json2);
  });

  test('costOutDeal basic', () {
    final systemsCache = _MockSystemsCache();
    when(() => systemsCache.waypointFromSymbol('X-S-A')).thenReturn(
      SystemWaypoint(
        symbol: 'X-S-A',
        type: WaypointType.ASTEROID_FIELD,
        x: 0,
        y: 0,
      ),
    );
    when(() => systemsCache.waypointFromSymbol('X-S-B')).thenReturn(
      SystemWaypoint(
        symbol: 'X-S-B',
        type: WaypointType.PLANET,
        x: 0,
        y: 0,
      ),
    );
    const deal = Deal(
      sourceSymbol: 'X-S-A',
      destinationSymbol: 'X-S-B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final costed = costOutDeal(
      systemsCache,
      deal,
      cargoSize: 1,
      shipSpeed: 1,
    );

    /// These aren't very useful numbers, I don't think it takes 15s to fly
    /// 0 distance (even between orbitals)?
    expect(costed.fuelCost, 0);
    expect(costed.tradeVolume, 1);
    expect(costed.time, 15);
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
      fuelCost: 1,
      tradeVolume: 1,
      time: 1,
    );
    final profit = lightGreen.wrap('     +1c (100%)');
    expect(
      describeCostedDeal(costed),
      'FUEL                       A       1c -> B       2c $profit 1s 0c/s 2c',
    );
  });

  test('findDealFor smoketest', () async {
    final marketPrices = _MockPriceData();
    final systemsCache = _MockSystemsCache();
    final waypointCache = _MockWaypointCache();
    final marketCache = _MockMarketCache();
    final ship = _MockShip();
    final shipNav = _MockShipNav();
    when(() => ship.nav).thenReturn(shipNav);
    when(() => shipNav.systemSymbol).thenReturn('S-A');
    when(() => marketCache.marketsInJumpRadius(startSystem: 'S-A', maxJumps: 1))
        .thenAnswer((_) => const Stream.empty());

    final logger = _MockLogger();
    final costed = await runWithLogger(
      logger,
      () => findDealFor(
        marketPrices,
        systemsCache,
        waypointCache,
        marketCache,
        ship,
        maxJumps: 1,
        maxOutlay: 100,
        availableSpace: 10,
      ),
    );
    expect(costed, isNull);
  });
}
