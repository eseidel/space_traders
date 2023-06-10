import 'package:file/memory.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/prices.dart';
import 'package:test/test.dart';

// Creates a fake price with good defaults.
Price makePrice({
  required String waypointSymbol,
  required String symbol,
  MarketTradeGoodSupplyEnum supply = MarketTradeGoodSupplyEnum.ABUNDANT,
  int purchasePrice = 1,
  int sellPrice = 1,
  int tradeVolume = 1,
  DateTime? timestamp,
}) {
  return Price(
    waypointSymbol: waypointSymbol,
    symbol: symbol,
    supply: supply,
    purchasePrice: purchasePrice,
    sellPrice: sellPrice,
    tradeVolume: tradeVolume,
    timestamp: timestamp ?? DateTime.now(),
  );
}

void main() {
  test('PriceData', () async {
    final fs = MemoryFileSystem();
    final a = makePrice(waypointSymbol: 'a', symbol: 'a');
    final b = makePrice(waypointSymbol: 'b', symbol: 'a');
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
    final a = makePrice(waypointSymbol: 'a', symbol: '1', sellPrice: 0);
    final priceData = PriceData([a], fs: fs);
    expect(
      priceData.recentSellPrice(marketSymbol: 'a', tradeSymbol: '1'),
      null,
    );
    // Works fine with a single non-zero sell price.
    final newA = makePrice(waypointSymbol: 'a', symbol: '1', sellPrice: 3);
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
    final a = makePrice(waypointSymbol: 'a', symbol: '1', sellPrice: 0);
    final priceData = PriceData([a], fs: fs);
    expect(
      priceData.medianSellPrice('1'),
      null,
    );
    // Works fine with a single non-zero sell price.
    final newA = makePrice(waypointSymbol: 'a', symbol: '1', sellPrice: 3);
    priceData.addPrices([newA]);
    expect(
      priceData.medianSellPrice('1'),
      3,
    );
  });

  test('percentileForSellPrice', () {
    final fs = MemoryFileSystem();
    final priceData = PriceData(
      [
        makePrice(waypointSymbol: 'a', symbol: 'a', sellPrice: 100),
        makePrice(waypointSymbol: 'b', symbol: 'a', sellPrice: 110),
        makePrice(waypointSymbol: 'c', symbol: 'a', sellPrice: 150),
        makePrice(waypointSymbol: 'd', symbol: 'a', sellPrice: 200),
        makePrice(waypointSymbol: 'e', symbol: 'a', sellPrice: 300),
      ],
      fs: fs,
    );
    expect(priceData.percentileForSellPrice('a', 100), 20);
    expect(priceData.percentileForSellPrice('a', 110), 40);
    expect(priceData.percentileForSellPrice('a', 150), 60);
    expect(priceData.percentileForSellPrice('a', 160), 60);
    expect(priceData.percentileForSellPrice('a', 200), 80);
    expect(priceData.percentileForSellPrice('a', 300), 100);
    expect(priceData.percentileForSellPrice('a', 400), 100);

    expect(priceData.sellPriceAtPercentile('a', 100), 300);
    expect(priceData.sellPriceAtPercentile('a', 0), 100);
    expect(priceData.sellPriceAtPercentile('a', 50), 150);
    expect(priceData.sellPriceAtPercentile('a', 25), 110);
  });
  test('percentileForPurchasePrice', () {
    final fs = MemoryFileSystem();
    final priceData = PriceData(
      [
        makePrice(waypointSymbol: 'a', symbol: 'a', purchasePrice: 100),
        makePrice(waypointSymbol: 'b', symbol: 'a', purchasePrice: 110),
        makePrice(waypointSymbol: 'c', symbol: 'a', purchasePrice: 150),
        makePrice(waypointSymbol: 'd', symbol: 'a', purchasePrice: 200),
        makePrice(waypointSymbol: 'e', symbol: 'a', purchasePrice: 300),
      ],
      fs: fs,
    );
    expect(priceData.percentileForPurchasePrice('a', 100), 20);
    expect(priceData.percentileForPurchasePrice('a', 110), 40);
    expect(priceData.percentileForPurchasePrice('a', 150), 60);
    expect(priceData.percentileForPurchasePrice('a', 160), 60);
    expect(priceData.percentileForPurchasePrice('a', 200), 80);
    expect(priceData.percentileForPurchasePrice('a', 300), 100);
    expect(priceData.percentileForPurchasePrice('a', 400), 100);

    expect(priceData.purchasePriceAtPercentile('a', 100), 300);
    expect(priceData.purchasePriceAtPercentile('a', 0), 100);
    expect(priceData.purchasePriceAtPercentile('a', 50), 150);
    expect(priceData.purchasePriceAtPercentile('a', 25), 110);
  });
}
