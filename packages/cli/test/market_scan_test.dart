import 'package:cli/cache/market_price_snapshot.dart';
import 'package:cli/market_scan.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketScane.fromMarketPrices', () async {
    final now = DateTime(2021);
    final marketPrices = MarketPriceSnapshot(
      [
        MarketPrice.fromMarketTradeGood(
          MarketTradeGood(
            symbol: TradeSymbol.ADVANCED_CIRCUITRY,
            type: MarketTradeGoodTypeEnum.EXPORT,
            tradeVolume: 100,
            purchasePrice: 100,
            sellPrice: 10,
            supply: SupplyLevel.ABUNDANT,
          ),
          WaypointSymbol.fromString('W-A-A'),
          now,
        ),
        MarketPrice.fromMarketTradeGood(
          MarketTradeGood(
            symbol: TradeSymbol.ADVANCED_CIRCUITRY,
            type: MarketTradeGoodTypeEnum.EXPORT,
            tradeVolume: 100,
            purchasePrice: 300,
            sellPrice: 200,
            supply: SupplyLevel.ABUNDANT,
          ),
          WaypointSymbol.fromString('W-A-B'),
          now,
        ),
      ],
    );
    final marketScan =
        MarketScan.fromMarketPrices(marketPrices, description: 'test');
    expect(marketScan.tradeSymbols, [TradeSymbol.ADVANCED_CIRCUITRY]);
  });
}
