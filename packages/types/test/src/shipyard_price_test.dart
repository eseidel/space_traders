import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

class _MockShipyardShip extends Mock implements ShipyardShip {}

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
    expect(price2.hashCode, price.hashCode);
    expect(json2, json);
  });

  test('ShipyardPrice.fromShipyardShip', () {
    final now = DateTime.utc(1969);
    final waypointSymbol = WaypointSymbol.fromString('S-A-W');
    final ship = _MockShipyardShip();
    const shipType = ShipType.EXPLORER;
    when(() => ship.type).thenReturn(shipType);
    when(() => ship.purchasePrice).thenReturn(1);
    final price =
        ShipyardPrice.fromShipyardShip(ship, waypointSymbol, getNow: () => now);
    expect(price.waypointSymbol, waypointSymbol);
    expect(price.shipType, shipType);
    expect(price.purchasePrice, 1);
    expect(price.timestamp, now);
  });
}
