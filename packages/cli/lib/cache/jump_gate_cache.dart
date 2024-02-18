import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:types/types.dart';

/// A cached of JumpGate connections.
/// Connections are not necessarily functional, you have to check
/// the ConstructionCache to see if they are under construction.
class JumpGateCache extends JsonListStore<JumpGate> {
  /// Creates a new JumpGate cache.
  JumpGateCache(
    super.records, {
    required super.fs,
    super.path = defaultCacheFilePath,
  });

  /// Load the JumpGate values from the cache.
  factory JumpGateCache.load(
    FileSystem fs, {
    String path = defaultCacheFilePath,
  }) {
    final records = JsonListStore.loadRecords<JumpGate>(
          fs,
          path,
          JumpGate.fromJson,
        ) ??
        [];
    return JumpGateCache(records, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/jump_gates.json';

  /// The JumpGate values.
  List<JumpGate> get values => records;

  /// The number of waypoints in the cache.
  int get waypointCount => values.length;

  /// Updates a [JumpGate] in the cache.
  void updateJumpGate(JumpGate jumpGate) {
    final index = records.indexWhere(
      (record) => record.waypointSymbol == jumpGate.waypointSymbol,
    );

    if (index >= 0) {
      records[index] = jumpGate;
    } else {
      records.add(jumpGate);
    }

    save();
  }

  /// Gets all jump gates for the given system.
  Iterable<JumpGate> recordsForSystem(SystemSymbol systemSymbol) {
    return values
        .where((record) => record.waypointSymbol.hasSystem(systemSymbol));
  }

  /// Gets the connections for the jump gate with the given symbol.
  Set<WaypointSymbol>? connectionsForSymbol(WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.connections;

  /// Gets the JumpGate for the given waypoint symbol.
  JumpGate? recordForSymbol(WaypointSymbol waypointSymbol) =>
      values.firstWhereOrNull(
        (record) => record.waypointSymbol == waypointSymbol,
      );

  /// Gets the JumpGate for the given waypoint symbol.
  Future<JumpGate> getOrFetch(
    Api api,
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    final cached = recordForSymbol(waypointSymbol);
    if (cached != null) {
      return cached;
    }
    final jumpGate = await getJumpGate(api, waypointSymbol);
    updateJumpGate(jumpGate);
    return jumpGate;
  }
}
