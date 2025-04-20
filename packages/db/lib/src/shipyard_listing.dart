import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Lookup a shipyard listing by WaypointSymbol.
Query shipyardListingByWaypointSymbolQuery(WaypointSymbol symbol) => Query(
  'SELECT * FROM shipyard_listing_ WHERE symbol = @symbol',
  parameters: {'symbol': symbol.waypoint},
);

/// Query all shipyard listings.
Query allShipyardListingsQuery() =>
    const Query('SELECT * FROM shipyard_listing_');

/// Query to upsert a shipyard listing.
Query upsertShipyardListingQuery(ShipyardListing listing) => Query('''
      INSERT INTO shipyard_listing_ (symbol, types)
      VALUES (@symbol, @types)
      ON CONFLICT (symbol) DO UPDATE SET
        types = @types
      ''', parameters: shipyardListingToColumnMap(listing));

/// Build a column map from a shipyard listing.
Map<String, dynamic> shipyardListingToColumnMap(ShipyardListing listing) => {
  'symbol': listing.waypointSymbol.toJson(),
  'types': listing.shipTypes.map((e) => e.toJson()).toList(),
};

/// Build a shipyard listing from a column map.
ShipyardListing shipyardListingFromColumnMap(Map<String, dynamic> values) {
  return ShipyardListing(
    waypointSymbol: WaypointSymbol.fromString(values['symbol'] as String),
    shipTypes:
        (values['types'] as List<dynamic>)
            .cast<String>()
            .map((e) => ShipType.fromJson(e)!)
            .toSet(),
  );
}
