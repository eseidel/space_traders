import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:types/types.dart';

typedef _Record = Map<WaypointSymbol, ShipyardListing>;

/// A cached of charted values from Waypoints.
class ShipyardListingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  ShipyardListingCache(
    super.entries, {
    required super.fs,
    super.path = defaultPath,
  }) : super(
          recordToJson: (_Record r) => r.map(
            (key, value) => MapEntry(
              key.toJson(),
              value.toJson(),
            ),
          ),
        );

  /// Load the charted values from the cache.
  factory ShipyardListingCache.load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final valuesBySymbol = JsonStore.loadRecord<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              WaypointSymbol.fromJson(key),
              ShipyardListing.fromJson(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    return ShipyardListingCache(
      valuesBySymbol,
      fs: fs,
      path: path,
    );
  }

  /// The default path to the cache file.
  static const defaultPath = 'data/shipyard_listings.json';

  /// The ShipyardListings by WaypointSymbol.
  Map<WaypointSymbol, ShipyardListing> get _listingBySymbol => record;

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

  /// Add ShipyardListing for the given Shipyard to the cache.
  void addShipyard(Shipyard shipyard) {
    final symbol = shipyard.waypointSymbol;
    final listing = ShipyardListing(
      waypointSymbol: symbol,
      shipTypes: shipyard.shipTypes.map((inner) => inner.type).toSet(),
    );
    _listingBySymbol[symbol] = listing;
    save();
  }
}
