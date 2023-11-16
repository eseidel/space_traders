import 'package:cli/cache/market_cache.dart';
import 'package:cli/cache/static_cache.dart';
import 'package:file/memory.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockTradeGoodsCache extends Mock implements TradeGoodCache {}

void main() {
  test('MarketListingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final tradeGoods = _MockTradeGoodsCache();
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');
    final listing = MarketListing(
      waypointSymbol: waypointSymbol,
    );
    MarketListingCache({waypointSymbol: listing}, tradeGoods, fs: fs).save();
    final loaded = MarketListingCache.load(fs, tradeGoods);
    expect(loaded.marketListingForSymbol(waypointSymbol), listing);

    final newSymbol = WaypointSymbol.fromString('T-W-O');
    final market = Market(
      symbol: newSymbol.waypoint,
      exports: [
        TradeGood(
          symbol: TradeSymbol.ALUMINUM,
          name: 'foo',
          description: 'bar',
        ),
      ],
    );
    loaded.addMarket(market);
    expect(loaded.marketListingForSymbol(newSymbol), isNotNull);
    expect(
      loaded.marketListingForSymbol(newSymbol)!.exports,
      [TradeSymbol.ALUMINUM],
    );
  });
}
