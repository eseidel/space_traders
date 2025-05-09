import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('recentSellPrice', () {
    final now = DateTime(2021);
    DateTime getNow() => now;
    final price = MarketPrice.test(
      waypointSymbol: WaypointSymbol.fromString('S-S-A'),
      symbol: TradeSymbol.FUEL,
      sellPrice: 100,
      timestamp: now,
    );
    final onePrice = MarketPriceSnapshot([price]);
    expect(
      onePrice.recentSellPrice(
        marketSymbol: price.waypointSymbol,
        price.symbol,
        getNow: getNow,
      ),
      price.sellPrice,
    );
  });
}
