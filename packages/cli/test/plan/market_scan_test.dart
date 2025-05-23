import 'package:cli/plan/market_scan.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketScan.fromMarketPrices', () async {
    final now = DateTime(2021);
    final marketPrices = MarketPriceSnapshot([
      MarketPrice.fromMarketTradeGood(
        MarketTradeGood(
          symbol: TradeSymbol.ADVANCED_CIRCUITRY,
          type: MarketTradeGoodType.EXPORT,
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
          type: MarketTradeGoodType.EXPORT,
          tradeVolume: 100,
          purchasePrice: 300,
          sellPrice: 200,
          supply: SupplyLevel.ABUNDANT,
        ),
        WaypointSymbol.fromString('W-A-B'),
        now,
      ),
    ]);
    final marketScan = MarketScan.fromMarketPrices(
      marketPrices,
      description: 'test',
    );
    expect(marketScan.tradeSymbols, [TradeSymbol.ADVANCED_CIRCUITRY]);
  });
}
