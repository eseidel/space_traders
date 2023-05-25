import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/auth.dart';
import 'package:space_traders_cli/extensions.dart';

// Need to make these generic for all paginated apis.

/// Fetches all pages from the given fetchPage function.
Stream<T> fetchAllPages<T, A>(
  A api,
  Future<(List<T>, Meta)> Function(A api, int page) fetchPage,
) async* {
  var page = 1;
  var count = 0;
  var remaining = 0;
  do {
    final (values, meta) = await fetchPage(api, page);
    count += values.length;
    remaining = meta.total - count;
    for (final value in values) {
      yield value;
    }
    page++;
  } while (remaining > 0);
}

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
  WaypointCache(this._api);

  final Map<String, List<Waypoint>> _waypointsBySystem = {};
  final Api _api;

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(String systemSymbol) async {
    if (_waypointsBySystem.containsKey(systemSymbol)) {
      return _waypointsBySystem[systemSymbol]!;
    }
    final waypoints = await _allWaypointsInSystem(_api, systemSymbol).toList();
    _waypointsBySystem[systemSymbol] = waypoints;
    return waypoints;
  }

  /// Fetch the waypoint with the given symbol.
  Future<Waypoint> waypoint(String waypointSymbol) async {
    final systemSymbol = parseWaypointString(waypointSymbol).system;
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints.firstWhere((w) => w.symbol == waypointSymbol);
  }
}

/// Fetches all of the user's ships.  Handles pagination from the server.
Stream<Ship> allMyShips(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.fleet.getMyShips(page: page);
    return (response!.data, response.meta);
  });
}

/// Fetches all of the user's contracts.  Handles pagination from the server.
Stream<Contract> allMyContracts(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.contracts.getContracts(page: page);
    return (response!.data, response.meta);
  });
}

/// Fetches all factions.  Handles pagination from the server.
Stream<Faction> getAllFactions(Api api) {
  return fetchAllPages(api, (api, page) async {
    final response = await api.factions.getFactions(page: page);
    return (response!.data, response.meta);
  });
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
  Future<Market?> marketForSymbol(String marketSymbol) async {
    if (_marketsBySymbol.containsKey(marketSymbol)) {
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
