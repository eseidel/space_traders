import 'package:db/db.dart';
import 'package:db/src/queries/shipyard_listing.dart';
import 'package:types/types.dart';

/// A store for shipyard listings.
class ShipyardListingStore {
  /// Create a new shipyard listing store.
  ShipyardListingStore(this._db);

  final Database _db;

  /// Get the shipyard listing for the given symbol.
  Future<ShipyardListing?> at(WaypointSymbol waypointSymbol) async {
    final query = shipyardListingByWaypointSymbolQuery(waypointSymbol);
    return _db.queryOne(query, shipyardListingFromColumnMap);
  }

  /// Get a snapshot of all shipyard listings.
  Future<ShipyardListingSnapshot> snapshotAll() async =>
      ShipyardListingSnapshot(await all());

  /// Get all shipyard listings.
  Future<Iterable<ShipyardListing>> all() async {
    final query = allShipyardListingsQuery();
    return _db.queryMany(query, shipyardListingFromColumnMap);
  }

  /// Update the given shipyard listing in the database.
  Future<void> upsert(ShipyardListing listing) async {
    await _db.execute(upsertShipyardListingQuery(listing));
  }
}
