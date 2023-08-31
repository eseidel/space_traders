import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketPrice JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = MarketPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      symbol: TradeSymbol.FUEL,
      supply: MarketTradeGoodSupplyEnum.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
      tradeVolume: 10,
      timestamp: moonLanding,
    );
    final json = price.toJson();
    final price2 = MarketPrice.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(json2, json);
  });
}
