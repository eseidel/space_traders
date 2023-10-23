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
    super.systems, {
    required super.fs,
    super.path = defaultCacheFilePath,
  }) : _index =
            Map.fromEntries(systems.map((e) => MapEntry(e.systemSymbol, e)));

  /// All systems in the game.
  List<System> get systems => List.unmodifiable(entries);

  List<System> get _systems => entries;

  final Map<SystemSymbol, System> _index;
  final Map<SystemSymbol, List<ConnectedSystem>> _connectedSystems = {};

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
    final systems = JsonListStore.load<System>(
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
    final system = systemBySymbol(symbol);
    return system.waypoints
        .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);
  }

  /// Return the system with the given [symbol].
  System systemBySymbol(SystemSymbol symbol) =>
      _index[symbol] ?? (throw ArgumentError('Unknown system $symbol'));

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

  /// Return the SystemWaypoints for the given [systemSymbol].
  /// Mostly exists for compatibility with WaypointCache.
  List<SystemWaypoint> waypointsInSystem(SystemSymbol systemSymbol) =>
      systemBySymbol(systemSymbol).waypoints;

  List<ConnectedSystem> _computeConnectedSystems(SystemSymbol systemSymbol) {
    final system = systemBySymbol(systemSymbol);
    if (!system.hasJumpGate) {
      return [];
    }
    // Get all systems within X distance of the given system.
    // This code is hot during init, so it's important to trim the list of
    // systems as fast as possible, so we first cull by distance.
    final inRange = _systems
        .where((s) => system.distanceTo(s) <= kJumpGateRange)
        .where((s) => s.symbol != systemSymbol.system)
        // hasJumpGate is not cached (we just check traits), so only calling it
        // on systems that are in range makes this about 2x faster.
        .where((s) => s.hasJumpGate);
    final connected = inRange
        .map(
          (s) => ConnectedSystem(
            symbol: s.symbol,
            sectorSymbol: s.sectorSymbol,
            type: s.type,
            x: s.x,
            y: s.y,
            distance: system.distanceTo(s),
          ),
        )
        .toList()
      ..sortBy<num>((e) => e.distance);
    // TODO(eseidel): sort by distance than symbol to be stable.
    return connected;
  }

  /// Return connected systems for the given [systemSymbol].
  List<ConnectedSystem> connectedSystems(SystemSymbol systemSymbol) {
    final cached = _connectedSystems[systemSymbol];
    if (cached != null) {
      return cached;
    }
    final connected = _computeConnectedSystems(systemSymbol);
    _connectedSystems[systemSymbol] = connected;
    return connected;
  }

  /// Yields a stream of system symbols that are within n jumps of the system.
  /// The system itself is included in the stream with distance 0.
  /// The stream is roughly ordered by distance from the start.
  Iterable<(SystemSymbol systemSymbol, int jumps)> systemSymbolsInJumpRadius({
    required SystemSymbol startSystem,
    required int maxJumps,
  }) sync* {
    var jumpsLeft = maxJumps;
    final currentSystemsToJumpFrom = <SystemSymbol>{startSystem};
    final oneJumpFurther = <SystemSymbol>{};
    final systemsExamined = <SystemSymbol>{};
    while (jumpsLeft >= 0) {
      while (currentSystemsToJumpFrom.isNotEmpty) {
        final jumpFrom = currentSystemsToJumpFrom.first;
        currentSystemsToJumpFrom.remove(jumpFrom);
        systemsExamined.add(jumpFrom);
        yield (jumpFrom, maxJumps - jumpsLeft);
        // Don't bother to check connections if we're out of jumps.
        if (jumpsLeft > 0) {
          final connectedSystems = this.connectedSystems(jumpFrom).toList();
          final sortedSystems =
              connectedSystems.sortedBy<num>((s) => s.distance);
          for (final connectedSystem in sortedSystems) {
            // Don't add systems we've already examined or are already in the
            // list to examine next.
            if (!systemsExamined.contains(connectedSystem.systemSymbol) &&
                !currentSystemsToJumpFrom
                    .contains(connectedSystem.systemSymbol)) {
              oneJumpFurther.add(connectedSystem.systemSymbol);
            }
          }
        }
      }
      currentSystemsToJumpFrom.addAll(oneJumpFurther);
      oneJumpFurther.clear();
      jumpsLeft--;
    }
  }

  /// Yields a stream of Systems that are within n jumps of the given system.
  /// Waypoints from the start system are included in the stream.
  /// The stream is roughly ordered by distance from the start.
  // Iterable<System> systemsInJumpRadius({
  //   required String startSystem,
  //   required int maxJumps,
  // }) sync* {
  //   for (final (String system, int _)
  //       in systemSymbolsInJumpRadius(
  //     startSystem: startSystem,
  //     maxJumps: maxJumps,
  //   )) {
  //     yield systemBySymbol(system);
  //   }
  // }

  Iterable<WaypointSymbol> waypointSymbolsInJumpRadius({
    required SystemSymbol startSystem,
    required int maxJumps,
  }) sync* {
    for (final (SystemSymbol system, int _) in systemSymbolsInJumpRadius(
      startSystem: startSystem,
      maxJumps: maxJumps,
    )) {
      final waypoints = waypointsInSystem(system);
      for (final waypoint in waypoints) {
        yield waypoint.waypointSymbol;
      }
    }
  }

  /// Yields a stream of SystemWaypoints that are within n jumps of the given
  /// system. Waypoints from the start system are included in the stream.
  /// The stream is roughly ordered by distance from the start.
  // Iterable<SystemWaypoint> waypointsInJumpRadius({
  //   required String startSystem,
  //   required int maxJumps,
  // }) sync* {
  //   for (final (String system, int _)
  //       in systemSymbolsInJumpRadius(
  //     startSystem: startSystem,
  //     maxJumps: maxJumps,
  //   )) {
  //     final waypoints = waypointsInSystem(system);
  //     for (final waypoint in waypoints) {
  //       yield waypoint;
  //     }
  //   }
  // }

  /// Yields a stream of system symbols that are within n jumps of the system.
  /// The system itself is included in the stream with distance 0.
  /// The stream is roughly ordered by distance from the start.
  /// This makes one more API call per system than systemsSymbolsInJumpRadius
  /// so use that one if you don't need the ConnectedSystem data.
// Stream<ConnectedSystem> connectedSystemsInJumpRadius({
//   required WaypointCache waypointCache,
//   required String startSystem,
//   required int maxJumps,
// }) async* {
//   final start = await waypointCache.systemBySymbol(startSystem);
//   await for (final (String system, int _) in systemSymbolsInJumpRadius(
//     waypointCache: waypointCache,
//     startSystem: startSystem,
//     maxJumps: maxJumps,
//   )) {
//     final destination = await waypointCache.systemBySymbol(system);
//     yield connectedSystemFromSystem(
//       destination,
//       _distanceBetweenSystems(start, destination),
//     );
//   }
// }
}
