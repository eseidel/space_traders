import 'package:cli/api.dart';
import 'package:cli/cache/charting_cache.dart';
import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Fetches all waypoints in a system.  Handles pagination from the server.
Stream<Waypoint> _allWaypointsInSystem(Api api, SystemSymbol system) {
  return fetchAllPages(api, (api, page) async {
    final response =
        await api.systems.getSystemWaypoints(system.system, page: page);
    return (response!.data, response.meta);
  });
}

/// Stores Waypoint objects fetched recently from the API.
class WaypointCache {
  /// Create a new WaypointCache.
  WaypointCache(
    Api api,
    SystemsCache systems,
    ChartingCache charting,
    ConstructionCache construction,
  )   : _api = api,
        _systemsCache = systems,
        _chartingCache = charting,
        _constructionCache = construction;

  // _waypointsBySystem is no longer very useful, mostly it holds onto
  // uncharted waypoints for a single loop, we could explicitly cache
  // uncharted waypoints for a set amount of time instead?
  final Map<SystemSymbol, List<Waypoint>> _waypointsBySystem = {};
  final Api _api;
  final SystemsCache _systemsCache;
  final ChartingCache _chartingCache;
  final ConstructionCache _constructionCache;

  // TODO(eseidel): This should not exist.  This should instead work like
  // the marketCache, where callers request with a given desired freshness.
  // Also, once a waypoint has been charted, it never changes.
  /// Used to reset part of the WaypointsCache every loop.
  void resetForLoop() {
    _waypointsBySystem.clear();
    // agentHeadquarters, connectedSystems, and jumpGates don't ever change.
  }

  /// Sythesizes a waypoint from cached values if possible.
  Waypoint? waypointFromCaches(WaypointSymbol waypointSymbol) {
    final values = _chartingCache.valuesForSymbol(waypointSymbol);
    if (values == null) {
      return null;
    }
    final systemWaypoint = _systemsCache.waypointFromSymbol(waypointSymbol);
    final traits = <WaypointTrait>[];
    for (final traitSymbol in values.traitSymbols) {
      final trait = _chartingCache.waypointTraits[traitSymbol];
      if (trait == null) {
        logger.warn('Traits cache missing trait: $traitSymbol');
        return null;
      }
      traits.add(trait);
    }

    final isUnderConstruction = _constructionCache.isUnderConstruction(
      waypointSymbol,
    );
    if (isUnderConstruction == null) {
      logger.warn('Construction cache missing construction: $waypointSymbol');
      return null;
    }

    return Waypoint(
      symbol: systemWaypoint.symbol,
      type: systemWaypoint.type,
      systemSymbol: systemWaypoint.systemSymbol.system,
      x: systemWaypoint.x,
      y: systemWaypoint.y,
      chart: values.chart,
      faction: values.faction,
      orbitals: systemWaypoint.orbitals,
      traits: traits,
      isUnderConstruction: isUnderConstruction,
    );
  }

  List<Waypoint>? _waypointsInSystemFromCache(SystemSymbol systemSymbol) {
    final systemWaypoints = _systemsCache.waypointsInSystem(systemSymbol);
    final cachedWaypoints = <Waypoint>[];
    for (final systemWaypoint in systemWaypoints) {
      final waypoint = waypointFromCaches(systemWaypoint.waypointSymbol);
      if (waypoint == null) {
        return null;
      }
      cachedWaypoints.add(waypoint);
    }
    return cachedWaypoints;
  }

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(SystemSymbol systemSymbol) async {
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
    await _addWaypointsToCaches(waypoints);
    return waypoints;
  }

  Future<void> _addWaypointsToCaches(List<Waypoint> waypoints) async {
    _chartingCache.addWaypoints(waypoints);
    for (final waypoint in waypoints) {
      // TODO(eseidel): Only getConstruction if no recent cached one?
      final construction = waypoint.isUnderConstruction
          ? await getConstruction(_api, waypoint.waypointSymbol)
          : null;
      _constructionCache.updateConstruction(
        waypointSymbol: waypoint.waypointSymbol,
        construction: construction,
      );
    }
  }

  /// Fetch the waypoint with the given symbol.
  Future<Waypoint> waypoint(WaypointSymbol waypointSymbol) async {
    final result = await _waypointOrNull(waypointSymbol);
    if (result == null) {
      throw ArgumentError('Unknown waypoint: $waypointSymbol');
    }
    return result;
  }

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  Future<Waypoint?> _waypointOrNull(WaypointSymbol waypointSymbol) async {
    final systemSymbol = waypointSymbol.systemSymbol;
    final cachedWaypoint = waypointFromCaches(waypointSymbol);
    if (cachedWaypoint != null) {
      return cachedWaypoint;
    }
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints
        .firstWhereOrNull((w) => w.symbol == waypointSymbol.waypoint);
  }
}
