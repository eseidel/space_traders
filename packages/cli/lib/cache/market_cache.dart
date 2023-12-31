import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:cli/net/queries.dart';
import 'package:types/types.dart';

typedef _Record = Map<WaypointSymbol, MarketListing>;

/// A cached of charted values from Waypoints.
class MarketListingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  MarketListingCache(
    super.entries, {
    required super.fs,
    super.path = defaultPath,
  }) : super(
          recordToJson: (_Record r) => r.map(
            (key, value) => MapEntry(
              key.toJson(),
              value.toJson(),
            ),
          ),
        );

  /// Load the charted values from the cache.
  factory MarketListingCache.load(
    FileSystem fs, {
    String path = defaultPath,
  }) {
    final valuesBySymbol = JsonStore.loadRecord<_Record>(
          fs,
          path,
          (Map<String, dynamic> j) => j.map(
            (key, value) => MapEntry(
              WaypointSymbol.fromJson(key),
              MarketListing.fromJson(value as Map<String, dynamic>),
            ),
          ),
        ) ??
        {};
    return MarketListingCache(
      valuesBySymbol,
      fs: fs,
      path: path,
    );
  }

  /// The default path to the cache file.
  static const defaultPath = 'data/market_listings.json';

  /// The MarketListings by WaypointSymbol.
  Map<WaypointSymbol, MarketListing> get _listingBySymbol => record;

  /// The WaypointSymbols.
  Iterable<WaypointSymbol> get waypointSymbols => _listingBySymbol.keys;

  /// The MarketListings.
  Iterable<MarketListing> get listings => _listingBySymbol.values;

  /// Fetch the MarketListing for the given WaypointSymbol.
  MarketListing? listingForSymbol(WaypointSymbol waypointSymbol) =>
      _listingBySymbol[waypointSymbol];

  /// Fetch the MarketListings for the given SystemSymbol.
  Iterable<MarketListing> listingsInSystem(SystemSymbol systemSymbol) =>
      listings.where((l) => l.waypointSymbol.hasSystem(systemSymbol));

  /// Fetch the MarketListing for the given WaypointSymbol.
  MarketListing? operator [](WaypointSymbol waypointSymbol) =>
      listingForSymbol(waypointSymbol);

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

  /// Add MarketListings for the given Market to the cache.
  void addMarket(Market market) {
    final symbol = market.waypointSymbol;
    final listing = MarketListing(
      waypointSymbol: symbol,
      imports: market.imports.map((t) => t.symbol).toSet(),
      exports: market.exports.map((t) => t.symbol).toSet(),
      exchange: market.exchange.map((t) => t.symbol).toSet(),
    );
    _listingBySymbol[symbol] = listing;
    save();
  }
}

/// Stores Market objects fetched recently from the API.
class MarketCache {
  /// Create a new MarketplaceCache.
  MarketCache(
    Api api,
    MarketListingCache marketListings,
    TradeGoodCache tradeGoods,
  )   : _api = api,
        _marketListings = marketListings,
        _tradeGoods = tradeGoods;

  final Api _api;
  final MarketListingCache _marketListings;
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
  void resetForLoop() {
    _marketsBySymbol.clear();
  }

  /// Get the market for the given waypoint symbol from the cache.
  Market? fromCache(WaypointSymbol waypointSymbol) {
    return _marketsBySymbol[waypointSymbol];
  }

  /// Fetch the waypoint with the given symbol.
  Future<Market> refreshMarket(
    WaypointSymbol waypointSymbol,
  ) async {
    final market = await getMarket(_api, waypointSymbol);
    _marketsBySymbol[waypointSymbol] = market;
    _marketListings.addMarket(market);
    _tradeGoods.addAll(market.listedTradeGoods);
    return market;
  }
}
