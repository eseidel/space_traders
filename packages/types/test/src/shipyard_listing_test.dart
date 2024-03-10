import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipyardListing.allowsTradeOf', () {
    final listing = ShipyardListing(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      shipTypes: const {ShipType.COMMAND_FRIGATE},
    );
    expect(listing.hasShip(ShipType.EXPLORER), isFalse);
    expect(listing.hasShip(ShipType.COMMAND_FRIGATE), isTrue);
  });

  test('ShipyardListing json round trip', () {
    final listing = ShipyardListing(
      waypointSymbol: WaypointSymbol.fromString('S-A-W'),
      shipTypes: const {ShipType.COMMAND_FRIGATE},
    );
    final json = listing.toJson();
    final listing2 = ShipyardListing.fromJson(json);
    expect(listing, listing2);
    expect(listing.hashCode, listing2.hashCode);
  });
}
