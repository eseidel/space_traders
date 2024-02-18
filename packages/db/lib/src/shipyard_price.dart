import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all shipyard prices.
Query allShipyardPricesQuery() => const Query('SELECT * FROM shipyard_price');

/// Query to upsert a shipyard price.
Query upsertShipyardPriceQuery(ShipyardPrice price) => Query(
      '''
      INSERT INTO shipyard_price (symbol, ship_type, purchase_price, timestamp)
      VALUES (@symbol, @ship_type, @purchase_price, @timestamp)
      ON CONFLICT (symbol, ship_type) DO UPDATE SET
        purchase_price = @purchase_price,
        timestamp = @timestamp
      ''',
      parameters: shipyardPriceToColumnMap(price),
    );

/// Build a column map from a shipyard price.
Map<String, dynamic> shipyardPriceToColumnMap(ShipyardPrice price) => {
      'symbol': price.waypointSymbol.toString(),
      'ship_type': price.shipType.toString(),
      'purchase_price': price.purchasePrice,
      'timestamp': price.timestamp.toIso8601String(),
    };

/// Build a shipyard price from a column map.
ShipyardPrice shipyardPriceFromColumnMap(Map<String, dynamic> values) {
  return ShipyardPrice(
    waypointSymbol: WaypointSymbol.fromString(values['symbol'] as String),
    shipType: ShipType.fromJson(values['ship_type'] as String)!,
    purchasePrice: values['purchase_price'] as int,
    timestamp: DateTime.parse(values['timestamp'] as String),
  );
}
