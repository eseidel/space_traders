import 'package:mocktail/mocktail.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:space_traders_cli/cache/waypoint_cache.dart';
import 'package:space_traders_cli/trading.dart';
import 'package:test/test.dart';

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
}
