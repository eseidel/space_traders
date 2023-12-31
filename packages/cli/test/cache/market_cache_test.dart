import 'package:cli/cache/market_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketListingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');
    final listing = MarketListing(
      waypointSymbol: waypointSymbol,
    );
    MarketListingCache({waypointSymbol: listing}, fs: fs).save();
    final loaded = MarketListingCache.load(fs);
    expect(loaded[waypointSymbol], listing);

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
    expect(loaded[newSymbol], isNotNull);
    expect(loaded[newSymbol]!.exports, [TradeSymbol.ALUMINUM]);
  });
}
