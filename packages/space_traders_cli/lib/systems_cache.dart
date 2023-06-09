import 'dart:convert';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:file/file.dart';
import 'package:http/http.dart' as http;
import 'package:space_traders_api/api.dart';
import 'package:space_traders_cli/extensions.dart';
import 'package:space_traders_cli/logger.dart';

int _distanceBetweenSystems(System a, System b) {
  // Use euclidean distance.
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy).round();
}

/// A cache of the systems in the game.
class SystemsCache {
  /// Create a new [SystemsCache] with the given [systems] and [fs].
  SystemsCache({
    required List<System> systems,
    required FileSystem fs,
    String cacheFilePath = defaultCacheFilePath,
  })  : _systems = systems,
        _fs = fs,
        _cacheFilePath = cacheFilePath;

  final List<System> _systems;
  final FileSystem _fs;
  final String _cacheFilePath;

  /// Default cache location.
  static const String defaultCacheFilePath = 'systems.json';

  /// Default url to fetch systems from.
  static const String defaultUrl =
      'https://api.spacetraders.io/v2/systems.json';

  static List<System> _parseSystems(String systemsString) {
    final parsed = jsonDecode(systemsString) as List<dynamic>;
    return parsed
        .map<System>((e) => System.fromJson(e as Map<String, dynamic>)!)
        .toList();
  }

  static SystemsCache? _loadSystemsCache(FileSystem fs, String cacheFilePath) {
    final systemsfile = fs.file(cacheFilePath);
    if (systemsfile.existsSync()) {
      return SystemsCache(
        systems: _parseSystems(systemsfile.readAsStringSync()),
        fs: fs,
        cacheFilePath: cacheFilePath,
      );
    }
    return null;
  }

  /// Save the cache to disk.
  Future<void> save() async {
    await _fs.file(_cacheFilePath).writeAsString(jsonEncode(_systems));
  }

  /// Load the cache from disk.
  static Future<SystemsCache> load(
    FileSystem fs, {
    String? cacheFilePath,
    String? url,
  }) async {
    final uri = Uri.parse(url ?? defaultUrl);
    final filePath = cacheFilePath ?? defaultCacheFilePath;
    // Try to load systems.json.  If it does not exist, pull down and cache
    // from the url.
    final fromCache = _loadSystemsCache(fs, filePath);
    if (fromCache != null) {
      return fromCache;
    } else {
      logger.info('Failed to load systems from cache, fetching from $uri');
    }

    try {
      final response = await http.get(uri);
      final systems = _parseSystems(response.body);
      final data =
          SystemsCache(systems: systems, fs: fs, cacheFilePath: filePath);
      await data.save();
      return data;
    } catch (e) {
      logger.warn('Failed to load systems from $uri: $e');
    }
    throw Exception('Failed to load systems from $uri');
  }

  /// Return the jump gate waypoint for the given [systemSymbol].
  SystemWaypoint? jumpGateWaypointForSystem(String systemSymbol) {
    final system = _systems.firstWhere((s) => s.symbol == systemSymbol);
    return system.waypoints
        .firstWhereOrNull((w) => w.type == WaypointType.JUMP_GATE);
  }

  System systemFromSymbol(String symbol) {
    return _systems.firstWhere((s) => s.symbol == symbol);
  }

  SystemWaypoint waypointFromSymbol(String symbol) {
    final parsed = parseWaypointString(symbol);
    final system = systemFromSymbol(parsed.system);
    return system.waypoints.firstWhere((w) => w.symbol == symbol);
  }

  /// Return connected systems for the given [systemSymbol].
  List<ConnectedSystem> connectedSystems(
    String systemSymbol, {
    int jumpGateRange = 2000,
  }) {
    final system = _systems.firstWhere((s) => s.symbol == systemSymbol);
    if (!system.hasJumpGate) {
      return [];
    }
    // Get all systems within X distance of the given system.
    final inRange = _systems
        .where((s) => s.symbol != systemSymbol)
        .where((s) => s.hasJumpGate)
        .where((s) => _distanceBetweenSystems(system, s) <= jumpGateRange)
        .toList();
    final connected = inRange
        .map(
          (s) => ConnectedSystem(
            symbol: s.symbol,
            sectorSymbol: s.sectorSymbol,
            type: s.type,
            x: s.x,
            y: s.y,
            distance: _distanceBetweenSystems(system, s),
          ),
        )
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    // TODO(eseidel): sort by distance than symbol to be stable.
    return connected;
  }
}
