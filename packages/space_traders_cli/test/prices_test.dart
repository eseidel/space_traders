import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:test/test.dart';

void main() {
  test('PriceData', () async {
    final a = Price(
      waypointSymbol: 'a',
      symbol: 'a',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 1,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    final b = Price(
      waypointSymbol: 'b',
      symbol: 'a',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 1,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    final priceData = PriceData([a, b]);
    expect(priceData.medianPurchasePrice('a'), 1);
    expect(priceData.medianSellPrice('a'), 1);
    expect(priceData.medianPurchasePrice('b'), null);
    expect(priceData.medianSellPrice('b'), null);
  });
}
