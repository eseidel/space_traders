import 'package:types/types.dart';

/// A cached of charted values from Waypoints.
class ShipyardListingSnapshot {
  /// Creates a new charting cache.
  ShipyardListingSnapshot(Iterable<ShipyardListing> listings)
    : _listingBySymbol = Map.fromEntries(
        listings.map((l) => MapEntry(l.waypointSymbol, l)),
      );

  /// The ShipyardListings by WaypointSymbol.
  final Map<WaypointSymbol, ShipyardListing> _listingBySymbol;

  /// The ShipyardListings.
  Iterable<ShipyardListing> get listings => _listingBySymbol.values;

  /// The number of ShipyardListings.
  int get count => _listingBySymbol.length;

  /// The number of waypoints with ShipyardListings.
  int get waypointCount => _listingBySymbol.keys.length;

  /// Fetch the ShipyardListings for the given SystemSymbol.
  Iterable<ShipyardListing> inSystem(SystemSymbol system) =>
      listings.where((l) => l.waypointSymbol.system == system);

  /// Count the number of ShipyardListings in the given SystemSymbol.
  int countInSystem(SystemSymbol system) => inSystem(system).length;

  /// The ShipyardListings which sell the given ship type.
  Iterable<ShipyardListing> withShip(ShipType shipType) {
    return listings.where((listing) => listing.hasShip(shipType));
  }

  /// Fetch the ShipyardListing for the given WaypointSymbol.
  ShipyardListing? at(WaypointSymbol waypointSymbol) =>
      _listingBySymbol[waypointSymbol];

  /// Fetch the ShipyardListing for the given WaypointSymbol.
  ShipyardListing? operator [](WaypointSymbol waypointSymbol) =>
      at(waypointSymbol);

  /// Returns true if we know of a Shipyard with the given ShipType.
  bool knowOfShipyardWithShip(ShipType shipType) {
    return listings.any((listing) => listing.hasShip(shipType));
  }
}
