import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketListing.allowsTradeOf', () {
    final market = MarketListing(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      exports: const {TradeSymbol.FUEL},
    );
    expect(market.allowsTradeOf(TradeSymbol.FABRICS), isFalse);
    expect(market.allowsTradeOf(TradeSymbol.FUEL), isTrue);
  });

  test('MarketListing json round trip', () {
    final market = MarketListing(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      exports: const {TradeSymbol.FUEL},
    );
    final json = market.toJson();
    final market2 = MarketListing.fromJson(json);
    expect(market, market2);
  });
}
