import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketListing.allowsTradeOf', () {
    final market = MarketListing(
      symbol: WaypointSymbol.fromString('S-A-W'),
      exports: const {TradeSymbol.FUEL},
    );
    expect(market.allowsTradeOf(TradeSymbol.FABRICS), isFalse);
    expect(market.allowsTradeOf(TradeSymbol.FUEL), isTrue);
  });
}
