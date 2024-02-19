import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all shipyard prices.
Query allShipyardPricesQuery() => const Query('SELECT * FROM shipyard_price_');

/// Query to upsert a shipyard price.
Query upsertShipyardPriceQuery(ShipyardPrice price) => Query(
      '''
      INSERT INTO shipyard_price_ (waypoint_symbol, ship_type, purchase_price, timestamp)
      VALUES (@waypoint_symbol, @ship_type, @purchase_price, @timestamp)
      ON CONFLICT (waypoint_symbol, ship_type) DO UPDATE SET
        purchase_price = @purchase_price,
        timestamp = @timestamp
      ''',
      parameters: shipyardPriceToColumnMap(price),
    );

/// Query to get the timestamp of the most recent shipyard price for a waypoint.
Query timestampOfMostRecentShipyardPriceQuery(WaypointSymbol symbol) => Query(
      'SELECT MAX(timestamp) FROM shipyard_price_ WHERE waypoint_symbol = @symbol',
      parameters: {'symbol': symbol.toJson()},
    );

/// Build a column map from a shipyard price.
Map<String, dynamic> shipyardPriceToColumnMap(ShipyardPrice price) => {
      'waypoint_symbol': price.waypointSymbol.toJson(),
      'ship_type': price.shipType.toJson(),
      'purchase_price': price.purchasePrice,
      'timestamp': price.timestamp,
    };

/// Build a shipyard price from a column map.
ShipyardPrice shipyardPriceFromColumnMap(Map<String, dynamic> values) {
  return ShipyardPrice(
    waypointSymbol:
        WaypointSymbol.fromString(values['waypoint_symbol'] as String),
    shipType: ShipType.fromJson(values['ship_type'] as String)!,
    purchasePrice: values['purchase_price'] as int,
    timestamp: values['timestamp'] as DateTime,
  );
}
