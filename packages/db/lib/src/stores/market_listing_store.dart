import 'package:db/db.dart';
import 'package:db/src/queries/market_listing.dart';
import 'package:types/types.dart';

/// A store for market listings.
class MarketListingStore {
  /// Create a new market listing store.
  MarketListingStore(this._db);

  final Database _db;

  /// Get the market listing for the given symbol.
  Future<MarketListing?> at(WaypointSymbol waypointSymbol) async {
    final query = marketListingByWaypointSymbolQuery(waypointSymbol);
    return _db.queryOne(query, marketListingFromColumnMap);
  }

  /// Get all market listings.
  Future<Iterable<MarketListing>> all() async {
    final query = allMarketListingsQuery();
    return _db.queryMany(query, marketListingFromColumnMap);
  }

  /// Get a snapshot of all market listings.
  Future<MarketListingSnapshot> snapshotAll() async {
    final listings = await all();
    return MarketListingSnapshot(listings);
  }

  /// Get a snapshot of all market listings in a system.
  Future<MarketListingSnapshot> snapshotSystem(SystemSymbol system) async {
    final listings = await inSystem(system);
    return MarketListingSnapshot(listings);
  }

  /// Get all market listings which sell fuel.
  Future<Set<WaypointSymbol>> marketsSellingFuel() async {
    final query = marketsWhichTradeFuelQuery();
    final list = await _db.queryMany(query, marketListingSymbolFromColumnMap);
    return list.toSet();
  }

  /// Get all market listings within a system.
  Future<Iterable<MarketListing>> inSystem(SystemSymbol system) async {
    final query = marketListingsInSystemQuery(system);
    return _db.queryMany(query, marketListingFromColumnMap);
  }

  /// Get all WaypointSymbols with a market importing the given tradeSymbol.
  Future<Iterable<WaypointSymbol>> withImportsInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWithImportInSystemQuery(system, tradeSymbol);
    return _db.queryMany(query, marketListingSymbolFromColumnMap);
  }

  /// Get all WaypointSymbols which buys [tradeSymbol] within [system].
  /// Buys means imports or exchange.
  Future<Iterable<WaypointSymbol>> whichBuysInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWhichBuysTradeSymbolInSystemQuery(system, tradeSymbol);
    return _db.queryMany(query, marketListingSymbolFromColumnMap);
  }

  /// Get all WaypointSymbols with a market importing the given tradeSymbol.
  Future<Iterable<WaypointSymbol>> whichExportsInSystem(
    SystemSymbol system,
    TradeSymbol tradeSymbol,
  ) async {
    final query = marketsWithExportInSystemQuery(system, tradeSymbol);
    return _db.queryMany(query, marketListingSymbolFromColumnMap);
  }

  /// Returns true if we know of a market which trades the given symbol.
  /// Means any of imports, exports, or exchange.
  Future<bool> whichTrades(TradeSymbol tradeSymbol) async {
    final query = knowOfMarketWhichTradesQuery(tradeSymbol);
    final result = await _db.execute(query);
    return result[0][0]! as bool;
  }

  /// Returns true only if the given waypoint symbol is known to sell fuel.
  /// Return false if the waypoint symbol is not known or does not sell fuel.
  Future<bool> sellsFuel(WaypointSymbol waypointSymbol) async =>
      (await at(waypointSymbol))?.allowsTradeOf(TradeSymbol.FUEL) ?? false;

  /// Update the given market listing in the database.
  Future<void> upsert(MarketListing listing) async {
    await _db.execute(upsertMarketListingQuery(listing));
  }
}
