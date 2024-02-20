import 'package:cli/cache/market_prices.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

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
    const a = TradeSymbol.FUEL;
    const b = TradeSymbol.FOOD;
    final aPrice = makePrice(waypointSymbol: 'S-S-A', symbol: a);
    final bPrice = makePrice(waypointSymbol: 'S-S-B', symbol: a);
    final marketPrices = MarketPriceSnapshot([aPrice, bPrice]);
    expect(marketPrices.medianPurchasePrice(a), 1);
    expect(marketPrices.medianSellPrice(a), 1);
    expect(marketPrices.medianPurchasePrice(b), null);
    expect(marketPrices.medianSellPrice(b), null);
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
    final now = DateTime(2021);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final price = MarketPrice.fromMarketTradeGood(
      good,
      waypointSymbol,
      now,
    );
    expect(price.symbol, TradeSymbol.FUEL);
    expect(price.waypointSymbol, waypointSymbol);
    expect(price.tradeVolume, 1);
    expect(price.supply, SupplyLevel.ABUNDANT);
    expect(price.purchasePrice, 1);
    expect(price.timestamp, now);
  });

  test('percentileForSellPrice', () {
    const a = TradeSymbol.FUEL;
    final marketPrices = MarketPriceSnapshot(
      [
        makePrice(waypointSymbol: 'S-S-A', symbol: a, sellPrice: 100),
        makePrice(waypointSymbol: 'S-S-B', symbol: a, sellPrice: 110),
        makePrice(waypointSymbol: 'S-S-C', symbol: a, sellPrice: 150),
        makePrice(waypointSymbol: 'S-S-D', symbol: a, sellPrice: 200),
        makePrice(waypointSymbol: 'S-S-E', symbol: a, sellPrice: 300),
      ],
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

  test('recentSellPrice', () {
    final price = makePrice(
      waypointSymbol: 'S-S-A',
      symbol: TradeSymbol.FUEL,
      sellPrice: 100,
      timestamp: _now,
    );
    final onePrice = MarketPriceSnapshot([price]);
    expect(
      onePrice.recentSellPrice(
        marketSymbol: price.waypointSymbol,
        price.symbol,
        getNow: _getNow,
      ),
      price.sellPrice,
    );
  });
}
