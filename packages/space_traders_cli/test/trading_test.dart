import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/trading.dart';
import 'package:test/test.dart';

import 'waypoints_cache_test.dart';

class MockWaypointCache extends Mock implements WaypointCache {}

class MockPriceData extends Mock implements PriceData {}

void main() {
  test('DealFinder empty', () {
    final priceData = MockPriceData();
    final finder = DealFinder(priceData);
    final deals = finder.findDeals();
    expect(deals, isEmpty);
  });

  test('DealFinder single deal', () {
    final priceData = MockPriceData();
    final tradeGood =
        TradeGood(symbol: TradeSymbol.FUEL, name: 'Fuel', description: '');
    final finder = DealFinder(priceData)
      ..visitMarket(
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
      )
      ..visitMarket(
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
      );
    final deals = finder.findDeals();
    expect(deals, isNotEmpty);
  });

  test('estimateSellPrice null', () {
    final priceData = MockPriceData();
    final estimate = estimateSellPrice(priceData, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePurchasePrice null', () {
    final priceData = MockPriceData();
    final estimate =
        estimatePurchasePrice(priceData, Market(symbol: 'A'), 'FUEL');
    expect(estimate, null);
  });

  test('estimatePrice fresh', () {
    final priceData = MockPriceData();
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
        priceData,
        market,
        'FUEL',
      ),
      2,
    );
    expect(
      estimatePurchasePrice(
        priceData,
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
    final systemsCache = MockSystemsCache();
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
}
