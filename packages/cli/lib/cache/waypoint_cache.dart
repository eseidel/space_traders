import 'package:cli/caches.dart';
import 'package:cli/logger.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:db/db.dart';
import 'package:types/config.dart';
import 'package:types/types.dart';

/// Stores Waypoint objects fetched recently from the API.
// TODO(eseidel): This is really the WaypointFetcher, the only thing
// this class knows how to map from the API concept of a Waypoint to
// how we store waypoint information in our database caches.
class WaypointCache {
  /// Create a new WaypointCache.
  WaypointCache(Api api, Database db) : _api = api, _db = db;

  final Database _db;
  final Api? _api;

  Future<Waypoint?> _waypointOrNullFromCache(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final cachedWaypoint = await waypointFromCaches(
      waypointSymbol,
      maxAge: maxAge,
    );
    return cachedWaypoint;
  }

  Future<List<Waypoint>?> _waypointsInSystemFromCache(
    SystemSymbol systemSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final systemWaypoints = await _db.systems.waypointsInSystem(systemSymbol);
    final cachedWaypoints = <Waypoint>[];
    for (final systemWaypoint in systemWaypoints) {
      // TODO(eseidel): Could make this a single db query by fetching all
      // construction records up front.
      final waypoint = await _waypointOrNullFromCache(
        systemWaypoint.symbol,
        maxAge: maxAge,
      );
      if (waypoint == null) {
        return null;
      }
      cachedWaypoints.add(waypoint);
    }
    return cachedWaypoints;
  }

  /// Fetch all waypoints in the given system.
  Future<List<Waypoint>> waypointsInSystem(
    SystemSymbol systemSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    // Check if all waypoints are in the charting cache.
    final cachedWaypoints = await _waypointsInSystemFromCache(
      systemSymbol,
      maxAge: maxAge,
    );
    if (cachedWaypoints != null) {
      return cachedWaypoints;
    }
    final api = _api;
    if (api == null) {
      throw StateError('$systemSymbol not in cache and no API to fetch it.');
    }

    final waypoints = await allWaypointsInSystem(api, systemSymbol).toList();
    await _addWaypointsToCaches(api, waypoints);
    return waypoints;
  }

  Future<void> _addWaypointsToCaches(Api api, List<Waypoint> waypoints) async {
    await _db.charting.addWaypoints(waypoints);
    await _db.waypointTraits.addAll(waypoints.expand((w) => w.traits));
    for (final waypoint in waypoints) {
      // TODO(eseidel): Only getConstruction if no recent cached one?
      final construction = waypoint.isUnderConstruction
          ? await getConstruction(api, waypoint.symbol)
          : null;
      await _db.construction.updateConstruction(waypoint.symbol, construction);
    }
  }

  /// Fetch the chart for the given waypoint and add it to the cache.
  static Future<Chart?> forceUpdateChart(
    Api api,
    Database db,
    WaypointSymbol waypointSymbol,
  ) async {
    final waypoint = await fetchWaypoint(api, waypointSymbol);
    await db.charting.addWaypoint(waypoint);
    return waypoint.chart;
  }

  /// Fetch the chart for the given waypoint if not in cache.
  Future<Chart?> fetchChart(WaypointSymbol waypointSymbol) async {
    final api = _api;
    if (api == null) {
      throw StateError('This api does not work in offline mode.');
    }
    final values = await _db.charting.chartedValues(waypointSymbol);
    if (values != null) {
      return values.chart;
    }
    return forceUpdateChart(_api!, _db, waypointSymbol);
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
        await _db.charting.isCharted(waypointSymbol, maxAge: maxAge) ?? false;
    if (isCharted) {
      return true;
    }
    return (await waypoint(waypointSymbol)).chart != null;
  }

  /// Returns true if the given waypoint is under construction.
  Future<bool> isUnderConstruction(WaypointSymbol waypointSymbol) async {
    // If we've cached a false result that can never change.
    final maybe = await _db.construction.isUnderConstruction(waypointSymbol);
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

  /// Synthesizes a waypoint from cached values if possible.
  Future<Waypoint?> waypointFromCaches(
    WaypointSymbol waypointSymbol, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final record = await _db.charting.chartingRecord(
      waypointSymbol,
      maxAge: maxAge,
    );
    if (record == null) {
      return null;
    }
    final isUnderConstruction = await _db.construction.isUnderConstruction(
      waypointSymbol,
      maxAge: maxAge,
    );
    if (isUnderConstruction == null) {
      return null;
    }

    final systemWaypoint = await _db.systems.waypoint(waypointSymbol);
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
      final trait = await _db.waypointTraits.get(traitSymbol);
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
}
