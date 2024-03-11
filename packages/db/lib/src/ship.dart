import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Get all ships from the database.
Query allShipsQuery() => const Query('SELECT * FROM ship_');

/// Get a ship by its [symbol] from the database.
Query shipBySymbolQuery(ShipSymbol symbol) => Query(
      'SELECT * FROM ship_ WHERE symbol = @symbol',
      parameters: {
        'symbol': symbol.toJson(),
      },
    );

/// Upsert a ship into the database.
Query upsertShipQuery(Ship ship) => Query(
      '''
      INSERT INTO ship_ (symbol, json)
      VALUES (@symbol, @json)
      ON CONFLICT (symbol) DO UPDATE SET json = @json
      ''',
      parameters: {
        'symbol': ship.symbol.toJson(),
        'json': ship.toJson(),
      },
    );

/// Convert a Ship to a column map.
Map<String, dynamic> shipToColumnMap(Ship ship) => {
      'symbol': ship.symbol.toJson(),
      'json': ship.toJson(),
    };

/// Convert a result row to a Ship.
Ship shipFromColumnMap(Map<String, dynamic> values) {
  return Ship.fromJson(values['json'] as Map<String, dynamic>);
}
