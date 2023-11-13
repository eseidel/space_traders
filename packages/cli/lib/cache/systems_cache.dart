import 'dart:convert';

import 'package:cli/api.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/logger.dart';
import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:types/types.dart';

/// Constant specifying the range of jump gates.
const kJumpGateRange = 2500;

/// A cache of the systems in the game.
class SystemsCache extends JsonListStore<System> {
  /// Create a new [SystemsCache] with the given [systems] and file system.
  SystemsCache(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  }) : _index =
            Map.fromEntries(records.map((e) => MapEntry(e.systemSymbol, e)));

  /// All systems in the game.
  List<System> get systems => List.unmodifiable(records);

  // List<System> get _systems => entries;

  final Map<SystemSymbol, System> _index;

  /// Default cache location.
  static const String defaultCacheFilePath = 'data/systems.json';

  /// Default url to fetch systems from.
  static const String defaultUrl =
      'https://api.spacetraders.io/v2/systems.json';

  static List<System> _parseSystems(String systemsString) {
    final parsed = jsonDecode(systemsString) as List<dynamic>;
    return parsed
        .map<System>((e) => System.fromJson(e as Map<String, dynamic>)!)
        .toList();
  }

  /// Load the cache from disk.
  static SystemsCache? loadCached(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final systems = JsonListStore.loadRecords<System>(
      fs,
      path,
      (json) => System.fromJson(json)!,
    );
    if (systems == null) {
      return null;
    }
    return SystemsCache(systems, fs: fs, path: path);
  }

  /// Load the cache from disk or fall back to fetching from the url.
  static Future<SystemsCache> load(
    FileSystem fs, {
    Future<http.Response> Function(Uri uri) httpGet = defaultHttpGet,
    String path = defaultCacheFilePath,
    String url = defaultUrl,
  }) async {
    // Try to load systems.json.
    final fromCache = loadCached(fs, path: path);
    if (fromCache != null) {
      return fromCache;
    }

    // If it does not exist, pull down and cache from the url.
    final uri = Uri.parse(url);
    logger.info('Failed to load systems from cache, fetching from $uri');
    try {
      final response = await httpGet(uri);
      if (response.statusCode >= 400) {
        throw ApiException(response.statusCode, response.body);
      }
      final systems = _parseSystems(response.body);
      final data = SystemsCache(systems, fs: fs, path: path)..save();
      return data;
    } catch (e) {
      logger.warn('Failed to load systems from $uri: $e');
      rethrow;
    }
  }

  /// Return the jump gate waypoint for the given [symbol].
  SystemWaypoint? jumpGateWaypointForSystem(SystemSymbol symbol) {
    return this[symbol]
        .waypoints
        .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);
  }

  /// Return the system with the given [symbol].
  // Remove in favor of operator [], only used for mocking.
  System systemBySymbol(SystemSymbol symbol) =>
      _index[symbol] ?? (throw ArgumentError('Unknown system $symbol'));

  /// Return the system with the given [symbol].
  System operator [](SystemSymbol symbol) => systemBySymbol(symbol);

  /// Fetch the waypoint with the given symbol, or null if it does not exist.
  SystemWaypoint? waypointOrNull(WaypointSymbol waypointSymbol) {
    final waypoints = waypointsInSystem(waypointSymbol.systemSymbol);
    return waypoints
        .firstWhereOrNull((w) => w.symbol == waypointSymbol.waypoint);
  }

  /// Return the SystemWaypoint for the given [symbol].
  SystemWaypoint waypointFromSymbol(WaypointSymbol symbol) =>
      waypointOrNull(symbol)!;

  /// Return the SystemWaypoint for the given [symbol].
  SystemWaypoint? waypointFromString(String symbol) =>
      waypointOrNull(WaypointSymbol.fromString(symbol));

  /// Returns true if the given [symbol] is a jump gate.
  bool isJumpGate(WaypointSymbol symbol) =>
      waypointFromSymbol(symbol).type == WaypointType.JUMP_GATE;

  /// Return the SystemWaypoints for the given [systemSymbol].
  /// Mostly exists for compatibility with WaypointCache.
  List<SystemWaypoint> waypointsInSystem(SystemSymbol systemSymbol) =>
      this[systemSymbol].waypoints;
}
