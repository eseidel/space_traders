import 'package:db/db.dart';
import 'package:types/types.dart';

/// A cached of charted values from Waypoints.
class ShipyardListingSnapshot {
  /// Creates a new charting cache.
  ShipyardListingSnapshot(Iterable<ShipyardListing> listings)
      : _listingBySymbol =
            Map.fromEntries(listings.map((l) => MapEntry(l.waypointSymbol, l)));

  /// Load the charted values from the cache.
  static Future<ShipyardListingSnapshot> load(Database db) async {
    final values = await db.allShipyardListings();
    return ShipyardListingSnapshot(values);
  }

  /// The ShipyardListings by WaypointSymbol.
  final Map<WaypointSymbol, ShipyardListing> _listingBySymbol;

  /// The ShipyardListings.
  Iterable<ShipyardListing> get listings => _listingBySymbol.values;

  /// The number of ShipyardListings.
  int get count => _listingBySymbol.length;

  /// The number of waypoints with ShipyardListings.
  int get waypointCount => _listingBySymbol.keys.length;

  /// Fetch the ShipyardListings for the given SystemSymbol.
  Iterable<ShipyardListing> listingsInSystem(SystemSymbol systemSymbol) =>
      listings.where((l) => l.waypointSymbol.hasSystem(systemSymbol));

  /// The ShipyardListings which sell the given ship type.
  Iterable<ShipyardListing> listingsWithShip(ShipType shipType) {
    return listings.where((listing) => listing.hasShip(shipType));
  }

  /// Fetch the ShipyardListing for the given WaypointSymbol.
  ShipyardListing? listingForSymbol(WaypointSymbol waypointSymbol) {
    return _listingBySymbol[waypointSymbol];
  }

  /// Fetch the ShipyardListing for the given WaypointSymbol.
  ShipyardListing? operator [](WaypointSymbol waypointSymbol) =>
      listingForSymbol(waypointSymbol);

  /// Returns true if we know of a Shipyard with the given ShipType.
  bool knowOfShipyardWithShip(ShipType shipType) {
    return listings.any((listing) => listing.hasShip(shipType));
  }
}

/// Add ShipyardListing for the given Shipyard to the cache.
void recordShipyardListing(Database db, Shipyard shipyard) {
  final symbol = shipyard.waypointSymbol;
  final listing = ShipyardListing(
    waypointSymbol: symbol,
    shipTypes: shipyard.shipTypes.map((inner) => inner.type).toSet(),
  );
  db.upsertShipyardListing(listing);
}
