import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';

/// Fetches all waypoints in a system.  Handles pagination from the server.
Stream<Waypoint> _allWaypointsInSystem(Api api, String system) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.systems.getSystemWaypoints(system, page: page);
    return (response!.data, response.meta);
  });
}

/// Stores Waypoint objects fetched recently from the API.
class WaypointCache {
  /// Create a new WaypointCache.
  WaypointCache(Api api, SystemsCache systemsCache, ChartingCache chartingCache)
      : _api = api,
        _systemsCache = systemsCache,
        _chartingCache = chartingCache;

  // _waypointsBySystem is no longer very useful, mostly it holds onto
  // uncharted waypoints for a single loop, we could explicitly cache
  // uncharted waypoints for a set amount of time instead?
  final Map<String, List<Waypoint>> _waypointsBySystem = {};
  // TODO(eseidel): remove _connectedSystemsBySystem.
  final Map<String, List<ConnectedSystem>> _connectedSystemsBySystem = {};
  final Api _api;
  final SystemsCache _systemsCache;
  final ChartingCache _chartingCache;

  // TODO(eseidel): This should not exist.  This should instead work like
  // the marketCache, where callers request with a given desired freshness.
  // Also, once a waypoint has been charted, it never changes.
  /// Used to reset part of the WaypointsCache every loop.
  void resetForLoop() {
    _waypointsBySystem.clear();
    // agentHeadquarters, connectedSystems, and jumpGates don't ever change.
  }

  List<Waypoint>? _waypointsInSystemFromCache(String systemSymbol) {
    final systemWaypoints = _systemsCache.waypointsInSystem(systemSymbol);
    final cachedWaypoints = <Waypoint>[];
    for (final systemWaypoint in systemWaypoints) {
      final waypoint = _chartingCache.waypointFromSymbol(
        _systemsCache,
        systemWaypoint.symbol,
      );
      if (waypoint == null) {
        return null;
      }
      cachedWaypoints.add(waypoint);
    }
    return cachedWaypoints;
  }

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(String systemSymbol) async {
    assertIsSystemSymbol(systemSymbol);
    if (_waypointsBySystem.containsKey(systemSymbol)) {
      return _waypointsBySystem[systemSymbol]!;
    }
    // Check if all waypoints are in the charting cache.
    final cachedWaypoints = _waypointsInSystemFromCache(systemSymbol);
    if (cachedWaypoints != null) {
      _waypointsBySystem[systemSymbol] = cachedWaypoints;
      return cachedWaypoints;
    }

    final waypoints = await _allWaypointsInSystem(_api, systemSymbol).toList();
    _waypointsBySystem[systemSymbol] = waypoints;
    _chartingCache.addWaypoints(waypoints);
    return waypoints;
  }

  /// Fetch the waypoint with the given symbol.
  Future<Waypoint> waypoint(String waypointSymbol) async {
    assertIsWaypointSymbol(waypointSymbol);
    final result = await _waypointOrNull(waypointSymbol);
    if (result == null) {
      throw ArgumentError('Unknown waypoint: $waypointSymbol');
    }
    return result;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<Waypoint?> _waypointOrNull(String waypointSymbol) async {
    assertIsWaypointSymbol(waypointSymbol);
    assert(waypointSymbol.split('-').length == 3, 'Invalid system symbol');
    final systemSymbol = parseWaypointString(waypointSymbol).system;
    final cachedWaypoint =
        _chartingCache.waypointFromSymbol(_systemsCache, waypointSymbol);
    if (cachedWaypoint != null) {
      return cachedWaypoint;
    }
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints.firstWhereOrNull((w) => w.symbol == waypointSymbol);
  }

  /// Fetch the waypoints with the given symbols.
  Stream<Waypoint> waypointsForSymbols(
    Iterable<String> waypointSymbols,
  ) async* {
    for (final symbol in waypointSymbols) {
      yield await waypoint(symbol);
    }
  }

  /// Return all connected systems in the given system.
  Stream<ConnectedSystem> connectedSystems(String systemSymbol) async* {
    assertIsSystemSymbol(systemSymbol);
    // Don't really need the _connectdSystemsBySystem with the SystemsCache.
    var cachedSystems = _connectedSystemsBySystem[systemSymbol];
    if (cachedSystems == null) {
      cachedSystems = _systemsCache.connectedSystems(systemSymbol);
      _connectedSystemsBySystem[systemSymbol] = cachedSystems;
    }
    for (final system in cachedSystems) {
      yield system;
    }
  }

  /// Returns a list of waypoints in the system with a shipyard.
  Future<List<Waypoint>> shipyardWaypointsForSystem(String systemSymbol) async {
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints.where((w) => w.hasShipyard).toList();
  }

  /// Returns a list of waypoints in the system with a marketplace.
  Future<List<Waypoint>> marketWaypointsForSystem(String systemSymbol) async {
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints.where((w) => w.hasMarketplace).toList();
  }

  /// Yields a stream of Waypoints that are within n jumps of the given system.
  /// Waypoints from the start system are included in the stream.
  /// The stream is roughly ordered by distance from the start.
  Stream<Waypoint> waypointsInJumpRadius({
    required String startSystem,
    required int maxJumps,
  }) async* {
    for (final (String system, int _)
        in _systemsCache.systemSymbolsInJumpRadius(
      startSystem: startSystem,
      maxJumps: maxJumps,
    )) {
      final waypoints = await waypointsInSystem(system);
      for (final waypoint in waypoints) {
        yield waypoint;
      }
    }
  }
}

/// Stores Market objects fetched recently from the API.
class MarketCache {
  /// Create a new MarketplaceCache.
  MarketCache(this._waypointCache);

  // This needs to be careful, this caches Market which can differ in
  // response depending on if we have a ship there or not.
  // A market with ship in orbit will have tradeGoods and transactions data.
  // Currently this only caches for one loop.
  final Map<String, Market?> _marketsBySymbol = {};
  final WaypointCache _waypointCache;

  // TODO(eseidel): This should not exist.  Callers should instead distinguish
  // between if they want market trade data (which is only availble when
  // a ship is in orbit).  If they don't, we shouldn't ever return it
  // and if we do, we should always fetch from the server.
  /// Used to reset part of the MarketCache every loop over the ships.
  void resetForLoop() {
    _marketsBySymbol.clear();
  }

  /// Fetch all markets in the given system.
  Stream<Market> marketsInSystem(String systemSymbol) async* {
    assertIsSystemSymbol(systemSymbol);
    final waypoints = await _waypointCache.waypointsInSystem(systemSymbol);
    for (final waypoint in waypoints) {
      final maybeMarket = await marketForSymbol(waypoint.symbol);
      if (maybeMarket != null) {
        yield maybeMarket;
      }
    }
  }

  /// Fetch the waypoint with the given symbol.
  Future<Market?> marketForSymbol(
    String marketSymbol, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _marketsBySymbol.containsKey(marketSymbol)) {
      return _marketsBySymbol[marketSymbol];
    }
    final waypoint = await _waypointCache.waypoint(marketSymbol);
    final maybeMarket = waypoint.hasMarketplace
        ? await getMarket(_waypointCache._api, waypoint)
        : null;
    _marketsBySymbol[marketSymbol] = maybeMarket;
    return maybeMarket;
  }
}
