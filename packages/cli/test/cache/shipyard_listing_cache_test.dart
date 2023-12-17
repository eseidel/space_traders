import 'package:cli/cache/shipyard_listing_cache.dart';
import 'package:file/memory.dart';
import 'package:test/test.dart';
import 'package:types/types.dart';

void main() {
  test('ShipyardListingCache load/save', () async {
    final fs = MemoryFileSystem.test();
    final waypointSymbol = WaypointSymbol.fromString('W-A-Y');
    final listing = ShipyardListing(
      waypointSymbol: waypointSymbol,
      shipTypes: const {ShipType.INTERCEPTOR},
    );
    ShipyardListingCache({waypointSymbol: listing}, fs: fs).save();
    final loaded = ShipyardListingCache.load(fs);
    expect(loaded[waypointSymbol], listing);

    final newSymbol = WaypointSymbol.fromString('T-W-O');
    final shipyard = Shipyard(
      symbol: newSymbol.waypoint,
      shipTypes: [
        ShipyardShipTypesInner(type: ShipType.EXPLORER),
      ],
      modificationsFee: 100,
    );
    loaded.addShipyard(shipyard);
    expect(loaded[newSymbol], isNotNull);
    expect(loaded[newSymbol]!.shipTypes, {ShipType.EXPLORER});
  });
}
