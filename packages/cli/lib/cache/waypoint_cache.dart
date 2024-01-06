import 'package:cli/cache/caches.dart';
import 'package:cli/config.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// Stores Waypoint objects fetched recently from the API.
class WaypointCache {
  /// Create a new WaypointCache.
  WaypointCache(
    Api api,
    SystemsCache systems,
    ChartingCache charting,
    ConstructionCache construction,
    WaypointTraitCache waypointTraits,
  )   : _api = api,
        _systemsCache = systems,
        _chartingCache = charting,
        _constructionCache = construction,
        _waypointTraits = waypointTraits;

  /// Create a new WaypointCache which only uses cached values.
  WaypointCache.cachedOnly(
    SystemsCache systems,
    ChartingCache charting,
    ConstructionCache construction,
    WaypointTraitCache waypointTraits,
  )   : _api = null,
        _systemsCache = systems,
        _chartingCache = charting,
        _constructionCache = construction,
        _waypointTraits = waypointTraits;

  // _waypointsBySystem is no longer very useful, mostly it holds onto
  // uncharted waypoints for a single loop, we could explicitly cache
  // uncharted waypoints for a set amount of time instead?
  final Map<SystemSymbol, List<Waypoint>> _waypointsBySystem = {};
  final Api? _api;
  final SystemsCache _systemsCache;
  final ChartingCache _chartingCache;
  final ConstructionCache _constructionCache;
  final WaypointTraitCache _waypointTraits;

  // TODO(eseidel): This should not exist.  This should instead work like
  // the marketCache, where callers request with a given desired freshness.
  // Also, once a waypoint has been charted, it never changes.
  /// Used to reset part of the WaypointsCache every loop.
  void resetForLoop() {
    _waypointsBySystem.clear();
    // agentHeadquarters, connectedSystems, and jumpGates don't ever change.
  }

  Future<Waypoint?> _waypointOrNullFromCache(
    WaypointSymbol waypointSymbol,
  ) async {
    final cachedWaypoint = await waypointFromCaches(
      _systemsCache,
      _chartingCache,
      _constructionCache,
      _waypointTraits,
      waypointSymbol,
    );
    return cachedWaypoint;
  }

  Future<List<Waypoint>?> _waypointsInSystemFromCache(
    SystemSymbol systemSymbol,
  ) async {
    final systemWaypoints = _systemsCache.waypointsInSystem(systemSymbol);
    final cachedWaypoints = <Waypoint>[];
    for (final systemWaypoint in systemWaypoints) {
      // TODO(eseidel): Could make this a single db query by fetching all
      // construction records up front.
      final waypoint = await _waypointOrNullFromCache(systemWaypoint.symbol);
      if (waypoint == null) {
        return null;
      }
      cachedWaypoints.add(waypoint);
    }
    return cachedWaypoints;
  }

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(SystemSymbol systemSymbol) async {
    // We can't currently remove this check, since charting cache doesn't
    // have uncharted waypoints.  We would need to have charting cache keep
    // track of uncharted waypoints and last time they were updated.
    if (_waypointsBySystem.containsKey(systemSymbol)) {
      return _waypointsBySystem[systemSymbol]!;
    }
    // Check if all waypoints are in the charting cache.
    final cachedWaypoints = await _waypointsInSystemFromCache(systemSymbol);
    if (cachedWaypoints != null) {
      _waypointsBySystem[systemSymbol] = cachedWaypoints;
      return cachedWaypoints;
    }
    final api = _api;
    if (api == null) {
      throw StateError('$systemSymbol not in cache and no API to fetch it.');
    }

    final waypoints = await allWaypointsInSystem(api, systemSymbol).toList();
    _waypointsBySystem[systemSymbol] = waypoints;
    await _addWaypointsToCaches(api, waypoints);
    return waypoints;
  }

  Future<void> _addWaypointsToCaches(Api api, List<Waypoint> waypoints) async {
    await _chartingCache.addWaypoints(waypoints);
    _waypointTraits.addAll(waypoints.expand((w) => w.traits));
    for (final waypoint in waypoints) {
      // TODO(eseidel): Only getConstruction if no recent cached one?
      final construction = waypoint.isUnderConstruction
          ? await getConstruction(api, waypoint.symbol)
          : null;
      await _constructionCache.updateConstruction(
        waypoint.symbol,
        construction,
      );
    }
  }

  /// Fetch the chart for the given waypoint if not in cache.
  Future<Chart?> fetchChart(WaypointSymbol waypointSymbol) async {
    final api = _api;
    if (api == null) {
      throw StateError('This api does not work in offline mode.');
    }
    final values = await _chartingCache.chartedValues(waypointSymbol);
    if (values != null) {
      return values.chart;
    }
    final waypoint = await fetchWaypoint(api, waypointSymbol);
    await _chartingCache.addWaypoint(waypoint);
    return waypoint.chart;
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
    final systemSymbol = waypointSymbol.system;
    final cachedWaypoint = await _waypointOrNullFromCache(waypointSymbol);
    if (cachedWaypoint != null) {
      return cachedWaypoint;
    }
    final waypoints = await waypointsInSystem(systemSymbol);
    return waypoints.firstWhereOrNull((w) => w.symbol == waypointSymbol);
  }

  /// Returns true if the given waypoint is known to be charted, will
  /// otherwise fetch the waypoint, update our caches and return that value.
  Future<bool> isCharted(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final isCharted =
        await _chartingCache.isCharted(waypointSymbol, maxAge: maxAge) ?? false;
    if (isCharted) {
      return true;
    }
    return (await waypoint(waypointSymbol)).chart != null;
  }

  /// Returns true if the given waypoint is under construction.
  Future<bool> isUnderConstruction(WaypointSymbol waypointSymbol) async {
    // If we've cached a false result that can never change.
    final maybe = await _constructionCache.isUnderConstruction(waypointSymbol);
    if (maybe == false) {
      return false;
    }
    // Could take a maxAge and only hit the network if we don't have a cached
    // value or it's too old.
    return (await waypoint(waypointSymbol)).isUnderConstruction;
  }

  /// Returns true if the given waypoint has a shipyard.
  Future<bool> hasShipyard(WaypointSymbol waypointSymbol) async {
    return (await waypoint(waypointSymbol)).hasShipyard;
  }

  /// Returns true if the given waypoint has a marketplace.
  Future<bool> hasMarketplace(WaypointSymbol waypointSymbol) async {
    return (await waypoint(waypointSymbol)).hasMarketplace;
  }

  /// Returns true if the given waypoint can be mined.
  Future<bool> canBeMined(WaypointSymbol waypointSymbol) async {
    return (await waypoint(waypointSymbol)).canBeMined;
  }

  /// Returns true if the given waypoint can be siphoned.
  Future<bool> canBeSiphoned(WaypointSymbol waypointSymbol) async {
    return (await waypoint(waypointSymbol)).canBeSiphoned;
  }
}

/// Synthesizes a waypoint from cached values if possible.
Future<Waypoint?> waypointFromCaches(
  SystemsCache systemsCache,
  ChartingCache chartingCache,
  ConstructionCache constructionCache,
  WaypointTraitCache waypointTraits,
  WaypointSymbol waypointSymbol, {
  Duration maxAge = defaultMaxAge,
}) async {
  final record =
      await chartingCache.chartingRecord(waypointSymbol, maxAge: maxAge);
  if (record == null) {
    return null;
  }
  final isUnderConstruction = await constructionCache.isUnderConstruction(
    waypointSymbol,
    maxAge: maxAge,
  );
  if (isUnderConstruction == null) {
    return null;
  }

  final systemWaypoint = systemsCache.waypoint(waypointSymbol);
  final values = record.values;
  if (values == null) {
    // Uncharted case.
    return Waypoint(
      symbol: systemWaypoint.symbol,
      type: systemWaypoint.type,
      position: systemWaypoint.position,
      orbitals: systemWaypoint.orbitals,
      isUnderConstruction: isUnderConstruction,
    );
  }

  final traits = <WaypointTrait>[];
  for (final traitSymbol in values.traitSymbols) {
    final trait = waypointTraits[traitSymbol];
    if (trait == null) {
      logger.warn('Traits cache missing trait: $traitSymbol');
      return null;
    }
    traits.add(trait);
  }

  return Waypoint(
    symbol: systemWaypoint.symbol,
    type: systemWaypoint.type,
    position: systemWaypoint.position,
    chart: values.chart,
    faction: values.faction,
    orbitals: systemWaypoint.orbitals,
    traits: traits,
    isUnderConstruction: isUnderConstruction,
  );
}
