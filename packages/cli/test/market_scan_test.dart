import 'package:cli/cache/market_prices.dart';
import 'package:cli/market_scan.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';

void main() {
  test('MarketScane.fromMarketPrices', () async {
    final fs = MemoryFileSystem.test();
    final marketPrices = MarketPrices([], fs: fs);
    final marketScan =
        MarketScan.fromMarketPrices(marketPrices, description: 'test');
    expect(marketScan.tradeSymbols, isEmpty);
  });
}
