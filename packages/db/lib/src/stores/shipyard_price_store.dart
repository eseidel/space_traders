import 'package:db/db.dart';
import 'package:db/src/queries/shipyard_price.dart';
import 'package:types/types.dart';

class ShipyardPriceStore {
  ShipyardPriceStore(this._db);

  final Database _db;

  /// Get all shipyard prices from the database.
  Future<Iterable<ShipyardPrice>> all() async {
    return _db.queryMany(allShipyardPricesQuery(), shipyardPriceFromColumnMap);
  }

  /// Get all shipyard prices from the database.
  Future<ShipyardPriceSnapshot> snapshotAll() async {
    final prices = await all();
    return ShipyardPriceSnapshot(prices.toList());
  }

  /// Get the shipyard price for the given waypoint and ship type.
  Future<ShipyardPrice?> at(
    WaypointSymbol waypointSymbol,
    ShipType shipType,
  ) async {
    final query = shipyardPriceQuery(waypointSymbol, shipType);
    return _db.queryOne(query, shipyardPriceFromColumnMap);
  }

  /// Add a shipyard price to the database.
  Future<void> upsert(ShipyardPrice price) async {
    await _db.execute(upsertShipyardPriceQuery(price));
  }
}
