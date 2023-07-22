import 'package:cli/api.dart';
import 'package:cli/cache/market_prices.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

// Creates a fake price with good defaults.
MarketPrice makePrice({
  required String waypointSymbol,
  required TradeSymbol symbol,
  MarketTradeGoodSupplyEnum supply = MarketTradeGoodSupplyEnum.ABUNDANT,
  int purchasePrice = 1,
  int sellPrice = 1,
  int tradeVolume = 1,
  DateTime? timestamp,
}) {
  return MarketPrice(
    waypointSymbol: waypointSymbol,
    symbol: symbol.value,
    supply: supply,
    purchasePrice: purchasePrice,
    sellPrice: sellPrice,
    tradeVolume: tradeVolume,
    timestamp: timestamp ?? DateTime.timestamp(),
  );
}

void main() {
  test('PriceData', () async {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    const b = TradeSymbol.FOOD;
    final aPrice = makePrice(waypointSymbol: 'a', symbol: a);
    final bPrice = makePrice(waypointSymbol: 'b', symbol: a);
    final marketPrices = MarketPrices([aPrice, bPrice], fs: fs);
    expect(marketPrices.medianPurchasePrice(a), 1);
    expect(marketPrices.medianSellPrice(a), 1);
    expect(marketPrices.medianPurchasePrice(b), null);
    expect(marketPrices.medianSellPrice(b), null);
  });

  test('PriceData.addPrices', () async {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    final aPrice = makePrice(waypointSymbol: 'a', symbol: a, purchasePrice: 10);
    final marketPrices = MarketPrices([aPrice], fs: fs);
    expect(marketPrices.count, 1);
    expect(marketPrices.waypointCount, 1);

    const b = TradeSymbol.FOOD;
    final bPrice = makePrice(waypointSymbol: 'b', symbol: b);
    await marketPrices.addPrices([bPrice]);
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);

    // Ignores invalid price dates
    final c = makePrice(
      waypointSymbol: 'c',
      symbol: TradeSymbol.ADVANCED_CIRCUITRY,
      timestamp: DateTime.now().add(const Duration(days: 1)),
    );
    final logger = _MockLogger();
    await runWithLogger(logger, () => marketPrices.addPrices([c]));
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);

    // Will replace prices with newer ones.
    expect(
      marketPrices.recentPurchasePrice(marketSymbol: 'a', a),
      10,
    );
    final d = makePrice(
      waypointSymbol: 'a',
      symbol: a,
      purchasePrice: 20,
    );
    await runWithLogger(logger, () => marketPrices.addPrices([d]));
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);
    expect(
      marketPrices.recentPurchasePrice(marketSymbol: 'a', a),
      20,
    );

    // But will ignore older prices.
    final e = makePrice(
      waypointSymbol: 'a',
      symbol: a,
      purchasePrice: 5,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    );
    await runWithLogger(logger, () => marketPrices.addPrices([e]));
    expect(
      marketPrices.recentPurchasePrice(marketSymbol: 'a', a),
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
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPrices(
      [
        makePrice(waypointSymbol: 'a', symbol: a, sellPrice: 100),
        makePrice(waypointSymbol: 'b', symbol: a, sellPrice: 110),
        makePrice(waypointSymbol: 'c', symbol: a, sellPrice: 150),
        makePrice(waypointSymbol: 'd', symbol: a, sellPrice: 200),
        makePrice(waypointSymbol: 'e', symbol: a, sellPrice: 300),
      ],
      fs: fs,
    );
    expect(marketPrices.percentileForSellPrice(a, 100), 20);
    expect(marketPrices.percentileForSellPrice(a, 110), 40);
    expect(marketPrices.percentileForSellPrice(a, 150), 60);
    expect(marketPrices.percentileForSellPrice(a, 160), 60);
    expect(marketPrices.percentileForSellPrice(a, 200), 80);
    expect(marketPrices.percentileForSellPrice(a, 300), 100);
    expect(marketPrices.percentileForSellPrice(a, 400), 100);
    expect(marketPrices.sellPriceAtPercentile(a, 100), 300);
    expect(marketPrices.sellPriceAtPercentile(a, 0), 100);
    expect(marketPrices.sellPriceAtPercentile(a, 50), 150);
    expect(marketPrices.sellPriceAtPercentile(a, 25), 110);
  });
  test('percentileForPurchasePrice', () {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPrices(
      [
        makePrice(waypointSymbol: 'a', symbol: a, purchasePrice: 100),
        makePrice(waypointSymbol: 'b', symbol: a, purchasePrice: 110),
        makePrice(waypointSymbol: 'c', symbol: a, purchasePrice: 150),
        makePrice(waypointSymbol: 'd', symbol: a, purchasePrice: 200),
        makePrice(waypointSymbol: 'e', symbol: a, purchasePrice: 300),
      ],
      fs: fs,
    );
    expect(marketPrices.percentileForPurchasePrice(a, 100), 20);
    expect(marketPrices.percentileForPurchasePrice(a, 110), 40);
    expect(marketPrices.percentileForPurchasePrice(a, 150), 60);
    expect(marketPrices.percentileForPurchasePrice(a, 160), 60);
    expect(marketPrices.percentileForPurchasePrice(a, 200), 80);
    expect(marketPrices.percentileForPurchasePrice(a, 300), 100);
    expect(marketPrices.percentileForPurchasePrice(a, 400), 100);

    expect(marketPrices.purchasePriceAtPercentile(a, 100), 300);
    expect(marketPrices.purchasePriceAtPercentile(a, 0), 100);
    expect(marketPrices.purchasePriceAtPercentile(a, 50), 150);
    expect(marketPrices.purchasePriceAtPercentile(a, 25), 110);
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
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPrices([], fs: fs);
    expect(marketPrices.hasRecentMarketData('a'), false);
    final oneMinuteAgo = DateTime.now().subtract(const Duration(minutes: 1));
    final aPrice =
        makePrice(waypointSymbol: 'a', symbol: a, timestamp: oneMinuteAgo);
    marketPrices.addPrices([aPrice]);
    expect(marketPrices.hasRecentMarketData('a'), true);
    expect(
      marketPrices.hasRecentMarketData('a', maxAge: const Duration(seconds: 1)),
      false,
    );
    expect(
      marketPrices.hasRecentMarketData('a', maxAge: const Duration(hours: 1)),
      true,
    );
  });

  test('recordMarketData', () async {
    final fs = MemoryFileSystem();
    final marketPrices = MarketPrices([], fs: fs);
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
    await recordMarketData(marketPrices, market);
    expect(marketPrices.hasRecentMarketData('a'), true);
    expect(marketPrices.count, 1);
  });

  test('PriceData save/load roundtrip', () async {
    final fs = MemoryFileSystem();
    final marketPrices = MarketPrices([], fs: fs);
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
    await recordMarketData(marketPrices, market);
    expect(marketPrices.hasRecentMarketData('a'), true);
    expect(marketPrices.count, 1);

    final marketPrices2 = MarketPrices.load(fs);
    expect(marketPrices2.hasRecentMarketData('a'), true);
    expect(marketPrices2.count, 1);
  });
}
