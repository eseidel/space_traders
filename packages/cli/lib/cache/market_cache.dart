import 'package:cli/cache/caches.dart';
import 'package:cli/net/queries.dart';
import 'package:db/db.dart';
import 'package:types/types.dart';

/// A cached of market listings.
class MarketListingSnapshot {
  /// Create a new MarketListingSnapshot.
  MarketListingSnapshot(Iterable<MarketListing> listings)
      : _listingBySymbol = Map.fromEntries(
          listings.map((l) => MapEntry(l.waypointSymbol, l)),
        );

  final Map<WaypointSymbol, MarketListing> _listingBySymbol;

  /// Load the MarketListingSnapshot from the database.
  static Future<MarketListingSnapshot> load(Database db) async {
    final listings = await db.allMarketListings();
    return MarketListingSnapshot(listings);
  }

  /// The WaypointSymbols.
  Iterable<WaypointSymbol> get waypointSymbols => _listingBySymbol.keys;

  /// The MarketListings.
  Iterable<MarketListing> get listings => _listingBySymbol.values;

  /// Fetch the MarketListings for the given SystemSymbol.
  Iterable<MarketListing> listingsInSystem(SystemSymbol systemSymbol) =>
      listings.where((l) => l.waypointSymbol.hasSystem(systemSymbol));

  /// Fetch the MarketListing for the given WaypointSymbol.
  MarketListing? operator [](WaypointSymbol waypointSymbol) =>
      _listingBySymbol[waypointSymbol];

  /// Find systems with at least N markets.
  Set<SystemSymbol> systemsWithAtLeastNMarkets(int n) {
    final systemMarketCounts = <SystemSymbol, int>{};
    for (final waypointSymbol in waypointSymbols) {
      final systemSymbol = waypointSymbol.system;
      systemMarketCounts[systemSymbol] =
          (systemMarketCounts[systemSymbol] ?? 0) + 1;
    }
    return systemMarketCounts.entries
        .where((e) => e.value >= n)
        .map((e) => e.key)
        .toSet();
  }
}

/// Stores Market objects fetched recently from the API.
class MarketCache {
  /// Create a new MarketplaceCache.
  MarketCache(
    Database db,
    Api api,
    TradeGoodCache tradeGoods,
  )   : _db = db,
        _api = api,
        _tradeGoods = tradeGoods;

  final Database _db;
  final Api _api;
  final TradeGoodCache _tradeGoods;

  // This needs to be careful, this caches Market which can differ in
  // response depending on if we have a ship there or not.
  // A market with ship in orbit will have tradeGoods and transactions data.
  // Currently this only caches for one loop.
  final Map<WaypointSymbol, Market?> _marketsBySymbol = {};

  // TODO(eseidel): MarketCache should not exist. Callers should instead
  // distinguish between if they want market trade data (which is only available
  // when a ship is in orbit).  If they don't, we shouldn't ever return it
  // and if we do, we should always fetch from the server.
  /// Used to reset part of the MarketCache every loop over the ships.
  void resetForLoop() => _marketsBySymbol.clear();

  /// Get the market for the given waypoint symbol from the cache.
  Market? fromCache(WaypointSymbol symbol) => _marketsBySymbol[symbol];

  /// Fetch the waypoint with the given symbol.
  Future<Market> refreshMarket(
    WaypointSymbol waypointSymbol,
  ) async {
    final market = await getMarket(_api, waypointSymbol);
    _marketsBySymbol[waypointSymbol] = market;
    await _db.upsertMarketListing(
      MarketListing(
        waypointSymbol: market.waypointSymbol,
        imports: market.imports.map((t) => t.symbol).toSet(),
        exports: market.exports.map((t) => t.symbol).toSet(),
        exchange: market.exchange.map((t) => t.symbol).toSet(),
      ),
    );
    _tradeGoods.addAll(market.listedTradeGoods);
    return market;
  }
}
