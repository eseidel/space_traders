import 'package:file/memory.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:test/test.dart';

void main() {
  test('PriceData', () async {
    final fs = MemoryFileSystem();
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
    final priceData = PriceData([a, b], fs: fs);
    expect(priceData.medianPurchasePrice('a'), 1);
    expect(priceData.medianSellPrice('a'), 1);
    expect(priceData.medianPurchasePrice('b'), null);
    expect(priceData.medianSellPrice('b'), null);
  });

  test('recentSellPrice ignores zero', () {
    // The prices db includes 0 are a sell price when something can't
    // be sold, so we should ignore them when looking for recent prices.
    final fs = MemoryFileSystem();
    final a = Price(
      waypointSymbol: 'a',
      symbol: '1',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 0,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    final priceData = PriceData([a], fs: fs);
    expect(
      priceData.recentSellPrice(marketSymbol: 'a', tradeSymbol: '1'),
      null,
    );
    // Works fine with a single non-zero sell price.
    final newA = Price(
      waypointSymbol: 'a',
      symbol: '1',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 3,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    priceData.addPrices([newA]);
    expect(
      priceData.recentSellPrice(marketSymbol: 'a', tradeSymbol: '1'),
      3,
    );
  });

  test('medianSellPrice ignores zero', () {
    // The prices db includes 0 are a sell price when something can't
    // be sold, so we should ignore them when looking for recent prices.
    final fs = MemoryFileSystem();
    final a = Price(
      waypointSymbol: 'a',
      symbol: '1',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 0,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    final priceData = PriceData([a], fs: fs);
    expect(
      priceData.medianSellPrice('1'),
      null,
    );
    // Works fine with a single non-zero sell price.
    final newA = Price(
      waypointSymbol: 'a',
      symbol: '1',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 3,
      tradeVolume: 1,
      timestamp: DateTime.now(),
    );
    priceData.addPrices([newA]);
    expect(
      priceData.medianSellPrice('1'),
      3,
    );
  });
}
