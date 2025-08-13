import 'package:db/db.dart';
import 'package:db/src/queries/ship.dart';
import 'package:types/types.dart';

/// Store for ships.
class ShipStore {
  /// Create a new survey store.
  ShipStore(this._db);

  final Database _db;

  /// Get all ships.
  Future<Iterable<Ship>> allShips() async {
    return _db.queryMany(allShipsQuery(), shipFromColumnMap);
  }

  /// Get a ship by symbol.
  Future<Ship?> get(ShipSymbol symbol) async {
    final query = shipBySymbolQuery(symbol);
    return _db.queryOne(query, shipFromColumnMap);
  }

  /// Upsert a ship into the database.
  Future<void> upsert(Ship ship) async {
    await _db.execute(upsertShipQuery(ship));
  }

  /// Add a list of ships to the database.
  Future<void> upsertAll(Iterable<Ship> ships) async {
    for (final ship in ships) {
      await upsert(ship);
    }
  }

  /// Delete a ship from the database.
  Future<void> remove(ShipSymbol symbol) async {
    await _db.execute(deleteShipQuery(symbol));
  }

  /// Return all ships.
  Future<Iterable<Ship>> all() async =>
      _db.queryMany(allShipsQuery(), shipFromColumnMap);
}
