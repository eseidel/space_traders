import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipyardPrice JSON roundtrip', () {
    final moonLanding = DateTime.utc(1969, 7, 20, 20, 18, 04);
    final price = ShipyardPrice(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      shipType: ShipType.EXPLORER,
      purchasePrice: 1,
      timestamp: moonLanding,
    );
    final json = price.toJson();
    final price2 = ShipyardPrice.fromJson(json);
    final json2 = price2.toJson();
    expect(price2, price);
    expect(json2, json);
  });
}
