import 'package:cli/cache/market_prices.dart';
import 'package:cli/logger.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockLogger extends Mock implements Logger {}

/// A DateTime for tests to use.
final _now = DateTime(2021);
DateTime _getNow() => _now;

// Creates a fake price with good defaults.
MarketPrice makePrice({
  required String waypointSymbol,
  required TradeSymbol symbol,
  SupplyLevel supply = SupplyLevel.ABUNDANT,
  int purchasePrice = 1,
  int sellPrice = 1,
  int tradeVolume = 1,
  DateTime? timestamp,
}) {
  return MarketPrice(
    waypointSymbol: WaypointSymbol.fromString(waypointSymbol),
    symbol: symbol,
    supply: supply,
    purchasePrice: purchasePrice,
    sellPrice: sellPrice,
    tradeVolume: tradeVolume,
    timestamp: timestamp ?? _now,
    activity: ActivityLevel.WEAK,
  );
}

void main() {
  test('PriceData', () async {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    const b = TradeSymbol.FOOD;
    final aPrice = makePrice(waypointSymbol: 'S-S-A', symbol: a);
    final bPrice = makePrice(waypointSymbol: 'S-S-B', symbol: a);
    final marketPrices = MarketPrices([aPrice, bPrice], fs: fs);
    expect(marketPrices.medianPurchasePrice(a), 1);
    expect(marketPrices.medianSellPrice(a), 1);
    expect(marketPrices.medianPurchasePrice(b), null);
    expect(marketPrices.medianSellPrice(b), null);
  });

  test('PriceData.addPrices', () async {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    final aPrice =
        makePrice(waypointSymbol: 'S-S-A', symbol: a, purchasePrice: 10);
    final marketPrices = MarketPrices([aPrice], fs: fs);
    expect(marketPrices.count, 1);
    expect(marketPrices.waypointCount, 1);

    const b = TradeSymbol.FOOD;
    final bPrice = makePrice(waypointSymbol: 'S-S-B', symbol: b);
    marketPrices.addPrices([bPrice]);
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);

    // Ignores invalid price dates
    final c = makePrice(
      waypointSymbol: 'S-S-C',
      symbol: TradeSymbol.ADVANCED_CIRCUITRY,
      timestamp: _now.add(const Duration(days: 1)),
    );
    final logger = _MockLogger();
    runWithLogger(logger, () => marketPrices.addPrices([c], getNow: _getNow));
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);

    // Will replace prices with newer ones.
    final market = WaypointSymbol.fromString('S-S-A');
    expect(
      marketPrices.recentPurchasePrice(
        marketSymbol: market,
        a,
        getNow: _getNow,
      ),
      10,
    );
    final d = makePrice(
      waypointSymbol: 'S-S-A',
      symbol: a,
      purchasePrice: 20,
    );
    runWithLogger(logger, () => marketPrices.addPrices([d], getNow: _getNow));
    expect(marketPrices.count, 2);
    expect(marketPrices.waypointCount, 2);
    expect(
      marketPrices.recentPurchasePrice(
        marketSymbol: market,
        a,
        getNow: _getNow,
      ),
      20,
    );

    // But will ignore older prices.
    final e = makePrice(
      waypointSymbol: 'S-S-A',
      symbol: a,
      purchasePrice: 5,
      timestamp: _now.subtract(const Duration(days: 1)),
    );
    runWithLogger(logger, () => marketPrices.addPrices([e], getNow: _getNow));
    expect(
      marketPrices.recentPurchasePrice(
        marketSymbol: market,
        a,
        getNow: _getNow,
      ),
      20,
    );
  });

  test('fromMarketTradeGood', () {
    final good = MarketTradeGood(
      symbol: TradeSymbol.FUEL,
      tradeVolume: 1,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
      type: MarketTradeGoodTypeEnum.EXCHANGE,
    );
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final price = MarketPrice.fromMarketTradeGood(
      good,
      waypointSymbol,
    );
    expect(price.symbol, TradeSymbol.FUEL);
    expect(price.waypointSymbol, waypointSymbol);
    expect(price.tradeVolume, 1);
    expect(price.supply, SupplyLevel.ABUNDANT);
    expect(price.purchasePrice, 1);
    expect(price.timestamp, isNotNull);
  });

  test('percentileForSellPrice', () {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPrices(
      [
        makePrice(waypointSymbol: 'S-S-A', symbol: a, sellPrice: 100),
        makePrice(waypointSymbol: 'S-S-B', symbol: a, sellPrice: 110),
        makePrice(waypointSymbol: 'S-S-C', symbol: a, sellPrice: 150),
        makePrice(waypointSymbol: 'S-S-D', symbol: a, sellPrice: 200),
        makePrice(waypointSymbol: 'S-S-E', symbol: a, sellPrice: 300),
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

  test('PriceData.hasRecentMarketData', () {
    final fs = MemoryFileSystem();
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPrices([], fs: fs);
    final marketSymbol = WaypointSymbol.fromString('S-A-W');
    expect(marketPrices.hasRecentData(marketSymbol), false);
    final oneMinuteAgo = _now.subtract(const Duration(minutes: 1));
    final aPrice = makePrice(
      waypointSymbol: marketSymbol.waypoint,
      symbol: a,
      timestamp: oneMinuteAgo,
    );
    marketPrices.addPrices([aPrice], getNow: _getNow);
    expect(marketPrices.hasRecentData(marketSymbol, getNow: _getNow), true);
    expect(
      marketPrices.hasRecentData(
        marketSymbol,
        maxAge: const Duration(seconds: 1),
        getNow: _getNow,
      ),
      false,
    );
    expect(
      marketPrices.hasRecentData(
        marketSymbol,
        maxAge: const Duration(hours: 1),
        getNow: _getNow,
      ),
      true,
    );
  });

  test('recentSellPrice', () {
    final fs = MemoryFileSystem();
    final price = makePrice(
      waypointSymbol: 'S-S-A',
      symbol: TradeSymbol.FUEL,
      sellPrice: 100,
      timestamp: _now,
    );
    final marketPrices = MarketPrices([price], fs: fs);
    expect(
      marketPrices.recentSellPrice(
        marketSymbol: price.waypointSymbol,
        price.symbol,
        getNow: _getNow,
      ),
      price.sellPrice,
    );
    final oneMinuteAgo = _now.subtract(const Duration(minutes: 1));
    final price2 = makePrice(
      waypointSymbol: 'S-S-A',
      symbol: TradeSymbol.CLOTHING,
      sellPrice: 200,
      timestamp: oneMinuteAgo,
    );
    marketPrices.addPrices([price2]);
    expect(
      marketPrices.recentSellPrice(
        marketSymbol: price2.waypointSymbol,
        price2.symbol,
        getNow: _getNow,
      ),
      price2.sellPrice,
    );
    expect(
      marketPrices.recentSellPrice(
        marketSymbol: price2.waypointSymbol,
        price2.symbol,
        getNow: _getNow,
        maxAge: const Duration(seconds: 1),
      ),
      isNull,
    );
  });

  test('recordMarketData', () async {
    final fs = MemoryFileSystem();
    final marketPrices = MarketPrices([], fs: fs);
    final marketSymbol = WaypointSymbol.fromString('S-A-W');
    final market = Market(
      symbol: marketSymbol.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.FUEL,
          tradeVolume: 1,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 1,
          sellPrice: 2,
        ),
      ],
    );
    await recordMarketData(marketPrices, market);
    expect(marketPrices.hasRecentData(marketSymbol), true);
    expect(marketPrices.count, 1);
  });

  test('PriceData save/load roundtrip', () async {
    final fs = MemoryFileSystem();
    final marketPrices = MarketPrices([], fs: fs);
    final marketSymbol = WaypointSymbol.fromString('S-A-W');
    final market = Market(
      symbol: marketSymbol.waypoint,
      tradeGoods: [
        MarketTradeGood(
          symbol: TradeSymbol.FUEL,
          tradeVolume: 1,
          supply: SupplyLevel.ABUNDANT,
          type: MarketTradeGoodTypeEnum.EXCHANGE,
          purchasePrice: 1,
          sellPrice: 2,
        ),
      ],
    );
    await recordMarketData(marketPrices, market);
    expect(marketPrices.hasRecentData(marketSymbol), true);
    expect(marketPrices.count, 1);

    final marketPrices2 = MarketPrices.load(fs);
    expect(marketPrices2.hasRecentData(marketSymbol), true);
    expect(marketPrices2.count, 1);
  });
}
