import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cache/waypoint_cache.dart';
import 'package:cli/net/queries.dart';

/// A synchronous local cache of what items a market trades?
// You want to be able to tell the difference between if we have a market
// cached or not.
// Pricing data is in MarketPrices.
// "what is traded", is the only thing we need to
// class MarketCache {
//   /// Create a new MarketCache.
//   MarketCache(this._waypointFetcher);
// }

/// Stores Market objects fetched recently from the API.
class MarketFetcher {
  /// Create a new MarketFetcher.
  MarketFetcher(
    Api api,
    WaypointFetcher waypointFetcher,
    SystemsCache systemsCache,
  )   : _api = api,
        _waypointFetcher = waypointFetcher,
        _systemsCache = systemsCache;

  // This needs to be careful, this caches Market which can differ in
  // response depending on if we have a ship there or not.
  // A market with ship in orbit will have tradeGoods and transactions data.
  // Currently this only caches for one loop.
  final Map<String, Market?> _marketsBySymbol = {};
  final Api _api;
  final WaypointFetcher _waypointFetcher;
  final SystemsCache _systemsCache;

  /// Fetch all markets in the given system.
  Stream<Market> marketsInSystem(String systemSymbol) async* {
    assertIsSystemSymbol(systemSymbol);
    final waypoints = await _waypointFetcher.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      final maybeMarket = await marketForSymbol(waypoint.symbol);
      if (maybeMarket != null) {
        yield maybeMarket;
      }
    }
  }

  /// Fetch the Market with the given symbol.
  Future<Market?> marketForSymbol(
    String marketSymbol, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _marketsBySymbol.containsKey(marketSymbol)) {
      return _marketsBySymbol[marketSymbol];
    }
    final waypoint = await _waypointFetcher.waypoint(marketSymbol);
    final maybeMarket =
        waypoint.hasMarketplace ? await getMarket(_api, waypoint) : null;
    _marketsBySymbol[marketSymbol] = maybeMarket;
    return maybeMarket;
  }

  /// Yields a stream of Markets that are within n jumps of the given system.
  Stream<Market> marketsInJumpRadius({
    required String startSystem,
    required int maxJumps,
  }) async* {
    for (final (String system, int _)
        in _systemsCache.systemSymbolsInJumpRadius(
      startSystem: startSystem,
      maxJumps: maxJumps,
    )) {
      yield* marketsInSystem(system);
    }
  }
}
