import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('MarketPrice JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = MarketPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      symbol: TradeSymbol.FUEL,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
      tradeVolume: 10,
      timestamp: moonLanding,
      activity: ActivityLevel.WEAK,
    );
    final json = price.toJson();
    final price2 = MarketPrice.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(price2.hashCode, price.hashCode);
    expect(json2, json);
  });

  test('MarketPrice.copyWith', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = MarketPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      symbol: TradeSymbol.FUEL,
      supply: SupplyLevel.ABUNDANT,
      purchasePrice: 1,
      sellPrice: 2,
      tradeVolume: 10,
      timestamp: moonLanding,
      activity: ActivityLevel.WEAK,
    );
    // Only sellPrice is currently supported.
    final price2 = price.copyWith(sellPrice: 4);
    expect(price2.purchasePrice, 1);
    expect(price2.sellPrice, 4);
    expect(price2.tradeVolume, 10);
    expect(price2.activity, ActivityLevel.WEAK);
  });
}
