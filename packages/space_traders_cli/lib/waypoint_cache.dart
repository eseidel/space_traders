import 'package:collection/collection.dart';
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/queries.dart';
import 'package:space_traders_cli/systems_cache.dart';

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
  final Map<String, System> _systemsBySymbol = {};
  final Map<String, List<Waypoint>> _waypointsBySystem = {};
  final Map<String, List<ConnectedSystem>> _connectedSystemsBySystem = {};
  final Map<String, JumpGate?> _jumpGatesBySystem = {};
  final Api _api;
  final SystemsCache _systemsCache;

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
    assert(systemSymbol.split('-').length == 2, 'Invalid system symbol');
    if (_waypointsBySystem.containsKey(systemSymbol)) {
      return _waypointsBySystem[systemSymbol]!;
    }
    final waypoints = await _allWaypointsInSystem(_api, systemSymbol).toList();
    _waypointsBySystem[systemSymbol] = waypoints;
    return waypoints;
  }

  /// Fetch the system waypoint with the given symbol.
  // Eventually callers should just have a SystemsCache instead.
  SystemWaypoint systemWaypoint(String waypointSymbol) {
    return _systemsCache.waypointFromSymbol(waypointSymbol);
  }

  /// Fetch the waypoint with the given symbol.
  Future<Waypoint> waypoint(String waypointSymbol) async {
    final result = await waypointOrNull(waypointSymbol);
    if (result == null) {
      throw ArgumentError('Unknown waypoint: $waypointSymbol');
    }
    return result;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<Waypoint?> waypointOrNull(String waypointSymbol) async {
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

  /// Fetch the system with the given symbol.
  Future<System> systemBySymbol(String systemSymbol) async {
    if (_systemsBySymbol.containsKey(systemSymbol)) {
      return _systemsBySymbol[systemSymbol]!;
    }
    final response = await _api.systems.getSystem(systemSymbol);
    final system = response!.data;
    _systemsBySymbol[systemSymbol] = system;
    return system;
  }

  Future<void> _ensureCacheMatchesServer(String systemSymbol) async {
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

  // When JumpGate has a symbol accessor, this can be removed.
  /// Returns the Waypoint for the jump gate in the given system, or null if
  /// there is no jump gate.
  Future<Waypoint?> jumpGateWaypointForSystem(String systemSymbol) async {
    final waypoints = await waypointsInSystem(systemSymbol);
    // There is at most one jump gate in a system.
    return waypoints.firstWhereOrNull(
      (w) => w.type == WaypointType.JUMP_GATE,
    );
  }

  /// Fetch the jump gate for the given system, or null if there is no jump
  /// gate.
  Future<JumpGate?> jumpGateForSystem(String systemSymbol) async {
    if (_jumpGatesBySystem.containsKey(systemSymbol)) {
      return _jumpGatesBySystem[systemSymbol];
    }
    final jumpGateWaypoint = await jumpGateWaypointForSystem(systemSymbol);
    if (jumpGateWaypoint == null) {
      _jumpGatesBySystem[systemSymbol] = null;
      return null;
    }
    final response = await _api.systems.getJumpGate(
      systemSymbol,
      jumpGateWaypoint.symbol,
    );
    final jumpGate = response!.data;
    _jumpGatesBySystem[systemSymbol] = jumpGate;
    return jumpGate;
  }
}

/// Fetches Market for a given Waypoint.
Future<Market> _getMarket(Api api, Waypoint waypoint) async {
  final response =
      await api.systems.getMarket(waypoint.systemSymbol, waypoint.symbol);
  return response!.data;
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

  /// Fetch all markets in the given system.
  Stream<Market> marketsInSystem(String systemSymbol) async* {
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
        ? await _getMarket(_waypointCache._api, waypoint)
        : null;
    _marketsBySymbol[marketSymbol] = maybeMarket;
    return maybeMarket;
  }
}

/// Returns JumpGate object for passed in Waypoint.
Future<JumpGate> getJumpGate(Api api, Waypoint waypoint) async {
  final response =
      await api.systems.getJumpGate(waypoint.systemSymbol, waypoint.symbol);
  return response!.data;
}