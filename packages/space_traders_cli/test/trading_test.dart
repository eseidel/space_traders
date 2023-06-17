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

  test('describe', () {
    final deal = Deal(
      sourceSymbol: 'A',
      destinationSymbol: 'B',
      tradeSymbol: TradeSymbol.FUEL,
      purchasePrice: 1,
      sellPrice: 2,
    );
    // Not clear why we have two of similar functions here.
    expect(
      describeDeal(deal),
      'FUEL                A     1c -> B     2c \x1B[92m   +1c (100%)\x1B[0m',
    );
    expect(
      dealDescription(deal),
      'Deal (\x1B[92m+1c\x1B[0m): FUEL 1c @ A -> 2c @ B profit: 1c per unit ',
    );
  });
}
