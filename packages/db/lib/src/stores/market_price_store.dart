import 'package:db/db.dart';
import 'package:db/src/queries/market_price.dart';
import 'package:db/src/query.dart';
import 'package:types/types.dart';

/// Store for market prices.
class MarketPriceStore {
  /// Create a new MarketPriceStore.
  MarketPriceStore(this._db);

  final Database _db;

  /// Get all market prices from the database.
  Future<Iterable<MarketPrice>> all() async {
    return _db.queryMany(allMarketPricesQuery(), marketPriceFromColumnMap);
  }

  /// Get all market prices within the given system.
  Future<Iterable<MarketPrice>> inSystem(SystemSymbol system) async {
    final query = marketPricesInSystemQuery(system);
    return _db.queryMany(query, marketPriceFromColumnMap);
  }

  /// Add a market price to the database.
  Future<void> upsert(MarketPrice price) async {
    await _db.execute(upsertMarketPriceQuery(price));
  }

  /// Get the market price for the given waypoint and trade symbol.
  Future<MarketPrice?> at(
    WaypointSymbol waypointSymbol,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketPriceQuery(waypointSymbol, tradeSymbol);
    return _db.queryOne(query, marketPriceFromColumnMap);
  }

  /// Get the median purchase price for the given trade symbol.
  Future<int?> medianPurchasePrice(TradeSymbol tradeSymbol) async {
    final query = medianMarketPurchasePriceQuery(tradeSymbol);
    final result = await _db.execute(query);
    return result[0][0] as int?;
  }

  /// Do this in sql instead.
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

  /// Check if the given waypoint has recent market prices.
  Future<bool> hasRecentAt(
    WaypointSymbol waypointSymbol,
    Duration maxAge,
  ) async {
    final query = timestampOfMostRecentMarketPriceQuery(waypointSymbol);
    return _hasRecentPrice(query, maxAge);
  }

  /// Count the number of market prices in the database.
  /// Each Waypoint might have many prices.
  Future<int> countPrices() async {
    final result = await _db.executeSql('SELECT COUNT(*) FROM market_price_');
    return result[0][0]! as int;
  }

  /// Count the number of unique symbols in the MarketPrices table.
  /// Each waypoint has up to one market with many prices.
  Future<int> countWaypoints() async {
    final result = await _db.executeSql(
      'SELECT COUNT(DISTINCT waypoint_symbol) FROM market_price_',
    );
    return result[0][0]! as int;
  }
}
