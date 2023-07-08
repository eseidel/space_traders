import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:file/file.dart';

/// Fetches all waypoints in a system.  Handles pagination from the server.
Stream<Waypoint> _allWaypointsInSystem(Api api, String system) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.systems.getSystemWaypoints(system, page: page);
    return (response!.data, response.meta);
  });
}

/// Charted values from a waypoint.
class ChartedValues {
  /// Create a new ChartedValues.
  const ChartedValues({
    required this.waypointSymbol,
    required this.orbitals,
    required this.faction,
    required this.traits,
    required this.chart,
  });

  factory ChartedValues.fromJson();

  /// The symbol of the waypoint these are for.
  final String waypointSymbol;

  /// Waypoints that orbit this waypoint.
  final List<WaypointOrbital> orbitals;

  /// Faction owning the waypoint.
  final WaypointFaction faction;

  /// The traits of the waypoint.
  final List<WaypointTrait> traits;

  /// The chart of the waypoint.
  final Chart chart;
}

Waypoint _waypointFromCache(SystemWaypoint waypoint, ChartedValues? charted) {
  return Waypoint(
    symbol: waypoint.symbol,
    type: waypoint.type,
    systemSymbol: waypoint.systemSymbol,
    x: waypoint.x,
    y: waypoint.y,
    orbitals: charted?.orbitals ?? [],
    faction: charted?.faction,
    traits: charted?.traits ?? [],
    chart: charted?.chart,
  );
}

class WaypointCache extends JsonListStore<ChartedValues> {
  WaypointCache(SystemsCache systemsCache) : _systemsCache = systemsCache;

  final SystemsCache _systemsCache;

  ChartedValues? chartingForSymbol(String waypointSymbol) {
    return entries.firstOrNull((e) => e.waypointSymbol == waypointSymbol);
  }

  /// Load the ContractCache from the file system.
  static WaypointCache? loadCached(SystemsCache systemsCache, FileSystem fs, {String path = defaultPath}) {
    final values = JsonListStore.load<ChartedValues>(
      fs,
      path,
      ChartedValues.fromJson,
    );
    if (values != null) {
      return WaypointCache(systemsCache, values, fs: fs, path: path);
    }
    return null;
  }

  static const defaultPath = 'data/charts.json';

  /// Fetch all waypoints in the given system.
  List<Waypoint>? waypointsInSystem(String systemSymbol) {
    final systemWaypoints = _systemsCache.waypointsInSystem(systemSymbol);
    final waypoints = <Waypoint>[];
    for (final waypoint in systemWaypoints) {
      final charted = _chartingByWaypointSymbol[waypoint.symbol];
      if (charted == null) {
        return null;
      }
      waypoints.add(_waypointFromCache(waypoint, charted));
    }
    return waypoints;
  }
}

/// Stores Waypoint objects fetched recently from the API.
class WaypointFetcher {
  /// Create a new WaypointCache.
  WaypointFetcher(
    Api api,
    WaypointCache waypointCache,
    SystemsCache systemsCache,
  )   : _api = api,
        _waypointCache = waypointCache,
        _systemsCache = systemsCache;

  final Map<String, List<Waypoint>> _waypointsBySystem = {};
  final Api _api;
  final WaypointCache _waypointCache;
  final SystemsCache _systemsCache;

  // TODO(eseidel): This should not exist.  This should instead work like
  // the marketCache, where callers request with a given desired freshness.
  // Also, once a waypoint has been charted, it never changes.
  /// Used to reset part of the WaypointsCache every loop.
  void resetForLoop() {
    _waypointsBySystem.clear();
    // agentHeadquarters, connectedSystems, and jumpGates don't ever change.
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
  List<ConnectedSystem> connectedSystems(String systemSymbol) {
    assertIsSystemSymbol(systemSymbol);
    return _systemsCache.connectedSystems(systemSymbol);
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
