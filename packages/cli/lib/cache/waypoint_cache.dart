import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
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
  WaypointCache(
    this._api,
    this._systemsCache, {
    this.ensureCacheMatchesServer = false,
  });

  Waypoint? _agentHeadquarters;
  final Map<String, List<Waypoint>> _waypointsBySystem = {};
  final Map<String, List<ConnectedSystem>> _connectedSystemsBySystem = {};
  final Map<String, JumpGate?> _jumpGatesBySystem = {};
  final Api _api;
  final SystemsCache _systemsCache;

  // TODO(eseidel): This should not exist.
  /// Used to reset part of the WaypointsCache every loop.
  void resetForLoop() {
    // _agentHeadquarters = null;
    _waypointsBySystem.clear();
    // _connectedSystemsBySystem.clear();
    // _jumpGatesBySystem.clear();
  }

  /// True if the WaypointCache should ensure that the SystemsCache matches
  /// the server
  final bool ensureCacheMatchesServer;

  /// Fetch the agent's headquarters.
  // Not sure this belongs on waypointCache, but should be cached somewhere.
  Future<Waypoint> getAgentHeadquarters() async {
    if (_agentHeadquarters != null) {
      return _agentHeadquarters!;
    }
    final agent = await getMyAgent(_api);
    _agentHeadquarters ??= await waypoint(agent.headquarters);
    return _agentHeadquarters!;
  }

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(String systemSymbol) async {
    assertIsSystemSymbol(systemSymbol);
    if (_waypointsBySystem.containsKey(systemSymbol)) {
      return _waypointsBySystem[systemSymbol]!;
    }
    final waypoints = await _allWaypointsInSystem(_api, systemSymbol).toList();
    _waypointsBySystem[systemSymbol] = waypoints;
    return waypoints;
  }

  /// Fetch the waypoint with the given symbol.
  Future<Waypoint> waypoint(String waypointSymbol) async {
    assertIsWaypointSymbol(waypointSymbol);
    final result = await waypointOrNull(waypointSymbol);
    if (result == null) {
      throw ArgumentError('Unknown waypoint: $waypointSymbol');
    }
    return result;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<Waypoint?> waypointOrNull(String waypointSymbol) async {
    assertIsWaypointSymbol(waypointSymbol);
    assert(waypointSymbol.split('-').length == 3, 'Invalid system symbol');
    final systemSymbol = parseWaypointString(waypointSymbol).system;
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

  Future<void> _ensureCacheMatchesServer(String systemSymbol) async {
    assertIsSystemSymbol(systemSymbol);
    if (!ensureCacheMatchesServer) {
      return;
    }
    void logSystems(List<ConnectedSystem> systems) {
      for (final system in systems) {
        logger.info('  ${system.symbol} - ${system.distance}');
      }
    }

    final cachedSystems = _connectedSystemsBySystem[systemSymbol];
    if (cachedSystems != null) {
      final jumpGate = await jumpGateForSystem(systemSymbol);
      final serverSystems =
          jumpGate == null ? <ConnectedSystem>[] : jumpGate.connectedSystems;
      // This equality seems too aggressive.
      if (!const DeepCollectionEquality().equals(
        cachedSystems,
        serverSystems,
      )) {
        logger
          ..err('SystemCache connectedSystems do not match server:')
          ..info('SystemCache:');
        logSystems(cachedSystems);
        logger.info('Server:');
        logSystems(serverSystems);
      }
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
      await _ensureCacheMatchesServer(systemSymbol);
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

  /// Fetch the jump gate for the given system, or null if there is no jump
  /// gate.
  Future<JumpGate?> jumpGateForSystem(String systemSymbol) async {
    if (_jumpGatesBySystem.containsKey(systemSymbol)) {
      return _jumpGatesBySystem[systemSymbol];
    }
    final jumpGateWaypoint =
        _systemsCache.jumpGateWaypointForSystem(systemSymbol);
    if (jumpGateWaypoint == null) {
      _jumpGatesBySystem[systemSymbol] = null;
      return null;
    }
    final jumpGate = await getJumpGate(_api, jumpGateWaypoint);
    _jumpGatesBySystem[systemSymbol] = jumpGate;
    return jumpGate;
  }

  /// Yields a stream of Waypoints that are within n jumps of the given system.
  /// Waypoints from the start system are included in the stream.
  /// The stream is roughly ordered by distance from the start.
  Stream<Waypoint> waypointsInJumpRadius({
    required String startSystem,
    required int maxJumps,
  }) async* {
    await for (final (String system, int _)
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

  // TODO(eseidel): This should not exist.
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

/// Fetches the waypoints for the given [ships].
Future<List<Waypoint>> waypointsForShips(
  WaypointCache waypointCache,
  List<Ship> ships,
) async {
  final shipWaypointSymbols = ships.map((s) => s.nav.waypointSymbol).toSet();
  return waypointCache.waypointsForSymbols(shipWaypointSymbols).toList();
}
