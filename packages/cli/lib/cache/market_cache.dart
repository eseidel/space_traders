import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_store.dart';
import 'package:cli/net/queries.dart';
import 'package:types/types.dart';

typedef _Record = Map<WaypointSymbol, MarketListing>;

/// A cached of charted values from Waypoints.
class MarketListingCache extends JsonStore<_Record> {
  /// Creates a new charting cache.
  MarketListingCache(
    super.entries,
    this.tradeGoods, {
    required super.fs,
    super.path = defaultPath,
  }) : super(
          recordToJson: (r) => r.map(
            (key, value) => MapEntry(
              key.toJson(),
              value.toJson(),
            ),
          ),
        );

  /// Load the charted values from the cache.
  factory MarketListingCache.load(
    FileSystem fs,
    TradeGoodCache tradeGoods, {
    String path = defaultPath,
  }) {
    final valuesBySymbol = JsonStore.load<_Record>(
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
      tradeGoods,
      fs: fs,
      path: path,
    );
  }

  /// The trade goods cache.
  final TradeGoodCache tradeGoods;

  /// The default path to the cache file.
  static const defaultPath = 'data/market_listings.json';

  /// The MarketListings by waypoint symbol.
  Map<WaypointSymbol, MarketListing> get _listingBySymbol => record;

  /// Fetch the waypoint with the given symbol.
  MarketListing? marketListingForSymbol(WaypointSymbol marketSymbol) {
    return _listingBySymbol[marketSymbol];
  }

  /// Add a market to the cache.
  void addMarket(Market market) {
    final symbol = market.waypointSymbol;
    final marketListing = MarketListing(
      symbol: symbol,
      imports: market.imports.map((t) => t.symbol).toList(),
      exports: market.exports.map((t) => t.symbol).toList(),
      exchange: market.exchange.map((t) => t.symbol).toList(),
    );
    tradeGoods.addAll(market.listedTradeGoods);
    _listingBySymbol[symbol] = marketListing;
    save();
  }

  /// Fill the cache from the given prices.
  void fillFromPrices(MarketPrices marketPrices) {
    final waypointSymbols =
        marketPrices.prices.map((p) => p.waypointSymbol).toSet();

    for (final waypointSymbol in waypointSymbols) {
      if (_listingBySymbol.containsKey(waypointSymbol)) {
        continue;
      }

      final prices = marketPrices.pricesAtMarket(waypointSymbol);
      final tradeSymbols = prices.map((p) => p.tradeSymbol).toSet();
      final listing = MarketListing(
        symbol: waypointSymbol,
        exchange: tradeSymbols.toList(),
      );
      _listingBySymbol[waypointSymbol] = listing;
    }
    save();
  }
}

/// Stores Market objects fetched recently from the API.
class MarketCache {
  /// Create a new MarketplaceCache.
  MarketCache(
    Api api,
    MarketListingCache marketListings,
    WaypointCache waypoints,
  )   : _api = api,
        _marketListings = marketListings,
        _waypoints = waypoints;

  final Api _api;
  final MarketListingCache _marketListings;
  final WaypointCache _waypoints;

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

  /// Fetch the waypoint with the given symbol.
  Future<Market?> marketForSymbol(
    WaypointSymbol marketSymbol, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _marketsBySymbol.containsKey(marketSymbol)) {
      return _marketsBySymbol[marketSymbol];
    }
    final waypoint = await _waypoints.waypoint(marketSymbol);
    final maybeMarket =
        waypoint.hasMarketplace ? await getMarket(_api, waypoint) : null;
    _marketsBySymbol[marketSymbol] = maybeMarket;
    if (maybeMarket != null) {
      _marketListings.addMarket(maybeMarket);
    }
    return maybeMarket;
  }
}
