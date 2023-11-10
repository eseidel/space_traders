import 'package:cli/cache/market_prices.dart';
import 'package:cli/market_scan.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketScane.fromMarketPrices', () async {
    final fs = MemoryFileSystem.test();
    final marketPrices = MarketPrices(
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
        ),
      ],
      fs: fs,
    );
    final marketScan =
        MarketScan.fromMarketPrices(marketPrices, description: 'test');
    expect(marketScan.tradeSymbols, [TradeSymbol.ADVANCED_CIRCUITRY]);
  });
}
