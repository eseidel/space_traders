import 'package:file/memory.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/prices.dart';
import 'package:test/test.dart';

// Creates a fake price with good defaults.
MarketPrice makePrice({
  required String waypointSymbol,
  required String symbol,
  MarketTradeGoodSupplyEnum supply = MarketTradeGoodSupplyEnum.ABUNDANT,
  int purchasePrice = 1,
  int sellPrice = 1,
  int tradeVolume = 1,
  DateTime? timestamp,
}) {
  return MarketPrice(
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

  test('PriceData.addPrices', () async {
    final fs = MemoryFileSystem();
    final a = makePrice(waypointSymbol: 'a', symbol: 'a', purchasePrice: 10);
    final b = makePrice(waypointSymbol: 'b', symbol: 'a');
    final priceData = PriceData([a], fs: fs);
    expect(priceData.count, 1);
    expect(priceData.waypointCount, 1);

    await priceData.addPrices([b]);
    expect(priceData.count, 2);
    expect(priceData.waypointCount, 2);

    // Ignores invalid price dates
    final c = makePrice(
      waypointSymbol: 'c',
      symbol: 'c',
      timestamp: DateTime.now().add(const Duration(days: 1)),
    );
    await priceData.addPrices([c]);
    expect(priceData.count, 2);
    expect(priceData.waypointCount, 2);

    // Will replace prices with newer ones.
    expect(
      priceData.recentPurchasePrice(marketSymbol: 'a', tradeSymbol: 'a'),
      10,
    );
    final d = makePrice(
      waypointSymbol: 'a',
      symbol: 'a',
      purchasePrice: 20,
    );
    await priceData.addPrices([d]);
    expect(priceData.count, 2);
    expect(priceData.waypointCount, 2);
    expect(
      priceData.recentPurchasePrice(marketSymbol: 'a', tradeSymbol: 'a'),
      20,
    );

    // But will ignore older prices.
    final e = makePrice(
      waypointSymbol: 'a',
      symbol: 'a',
      purchasePrice: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    );
    await priceData.addPrices([e]);
    expect(
      priceData.recentPurchasePrice(marketSymbol: 'a', tradeSymbol: 'a'),
      20,
    );
  });

  test('fromMarketTradeGood', () {
    final good = MarketTradeGood(
      symbol: 'A',
      tradeVolume: 1,
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
    );
    final price = MarketPrice.fromMarketTradeGood(good, 'W');
    expect(price.symbol, 'A');
    expect(price.waypointSymbol, 'W');
    expect(price.tradeVolume, 1);
    expect(price.supply, MarketTradeGoodSupplyEnum.ABUNDANT);
    expect(price.purchasePrice, 1);
    expect(price.timestamp, isNotNull);
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

  test('MarketPrice JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = MarketPrice(
      waypointSymbol: 'A',
      symbol: 'A',
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
      tradeVolume: 10,
      timestamp: moonLanding,
    );
    final json = price.toJson();
    final price2 = MarketPrice.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(json2, json);
  });

  test('PriceData.hasRecentMarketData', () {
    final fs = MemoryFileSystem();
    final priceData = PriceData([], fs: fs);
    expect(priceData.hasRecentMarketData('a'), false);
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final a =
        makePrice(waypointSymbol: 'a', symbol: 'a', timestamp: oneMinuteAgo);
    priceData.addPrices([a]);
    expect(priceData.hasRecentMarketData('a'), true);
    expect(
      priceData.hasRecentMarketData('a', maxAge: const Duration(seconds: 1)),
      false,
    );
    expect(
      priceData.hasRecentMarketData('a', maxAge: const Duration(hours: 1)),
      true,
    );
  });

  test('recordMarketData', () async {
    final fs = MemoryFileSystem();
    final priceData = PriceData([], fs: fs);
    final market = Market(
      symbol: 'a',
      tradeGoods: [
        MarketTradeGood(
          symbol: 'a',
          tradeVolume: 1,
          supply: MarketTradeGoodSupplyEnum.ABUNDANT,
          purchasePrice: 1,
          sellPrice: 2,
        )
      ],
    );
    await recordMarketData(priceData, market);
    expect(priceData.hasRecentMarketData('a'), true);
    expect(priceData.count, 1);
  });
}
