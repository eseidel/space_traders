import 'package:db/db.dart';
import 'package:db/src/queries/shipyard_price.dart';
import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// A store for shipyard prices.
class ShipyardPriceStore {
  /// Create a new [ShipyardPriceStore].
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

  Future<bool> _hasRecentPrice(Query query, Duration maxAge) async {
    final result = await _db.execute(query);
    if (result.isEmpty) {
      return false;
    }
    final timestamp = result[0][0] as DateTime?;
    if (timestamp == null) {
      return false;
    }
    return DateTime.now().difference(timestamp) < maxAge;
  }

  /// Check if the given waypoint has recent shipyard prices.
  Future<bool> hasRecent(WaypointSymbol waypointSymbol, Duration maxAge) async {
    final query = timestampOfMostRecentShipyardPriceQuery(waypointSymbol);
    return _hasRecentPrice(query, maxAge);
  }

  /// Count the number of shipyard prices in the database.
  Future<int> count() async {
    final result = await _db.executeSql('SELECT COUNT(*) FROM shipyard_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the ShipyardPrices table.
  Future<int> waypointCount() async {
    final result = await _db.executeSql(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM shipyard_price_',
    );
    return result[0][0]! as int;
  }
}
