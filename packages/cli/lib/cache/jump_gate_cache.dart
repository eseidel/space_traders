import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/net/queries.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

/// A cached JumpGate value.
@immutable
class JumpGateRecord extends Equatable {
  /// Creates a new JumpGateRecord.
  const JumpGateRecord({
    required this.waypointSymbol,
    required this.connections,
    required this.timestamp,
  });

  /// Creates a new JumpGateRecord from a JumpGate.
  factory JumpGateRecord.fromJumpGate(
    WaypointSymbol waypointSymbol,
    JumpGate jumpGate,
    DateTime now,
  ) {
    return JumpGateRecord(
      connections: jumpGate.connections.map(WaypointSymbol.fromString).toSet(),
      timestamp: now,
      waypointSymbol: waypointSymbol,
    );
  }

  /// Creates a new JumpGateRecord from JSON.
  factory JumpGateRecord.fromJson(Map<String, dynamic> json) {
    return JumpGateRecord(
      connections: (json['connections'] as List<dynamic>)
          .map((dynamic e) => e as String)
          .map(WaypointSymbol.fromJson)
          .toSet(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      waypointSymbol: WaypointSymbol.fromJson(json['waypointSymbol'] as String),
    );
  }

  /// The waypoint symbol.
  final WaypointSymbol waypointSymbol;

  /// The last time this record was updated.
  final DateTime timestamp;

  /// The connections for this jump gate.
  final Set<WaypointSymbol> connections;

  /// Converts this object to JumpGate model object.
  JumpGate toJumpGate() => JumpGate(
        connections: connections.map((e) => e.toString()).sorted(),
      );

  @override
  List<Object?> get props => [waypointSymbol, timestamp, connections];

  /// Converts this object to a JSON encodable object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'connections': connections.map((e) => e.toJson()).sorted(),
        'waypointSymbol': waypointSymbol.toJson(),
      };
}

/// A cached of JumpGate connections.
/// Connections are not necessarily functional, you have to check
/// the ConstructionCache to see if they are under construction.
class JumpGateCache extends JsonListStore<JumpGateRecord> {
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
    final records = JsonListStore.loadRecords<JumpGateRecord>(
          fs,
          path,
          JumpGateRecord.fromJson,
        ) ??
        [];
    return JumpGateCache(records, fs: fs, path: path);
  }

  /// The default path to the cache file.
  static const String defaultCacheFilePath = 'data/jump_gates.json';

  /// The JumpGate values.
  List<JumpGateRecord> get values => records;

  /// The number of waypoints in the cache.
  int get waypointCount => values.length;

  /// Updates a [JumpGate] in the cache.
  void updateJumpGate({
    required WaypointSymbol waypointSymbol,
    required JumpGate jumpGate,
    DateTime Function() getNow = defaultGetNow,
  }) {
    final index = records.indexWhere(
      (record) => record.waypointSymbol == waypointSymbol,
    );

    final newRecord =
        JumpGateRecord.fromJumpGate(waypointSymbol, jumpGate, getNow());
    if (index >= 0) {
      records[index] = newRecord;
    } else {
      records.add(newRecord);
    }

    save();
  }

  /// Gets all jump gates for the given system.
  Iterable<JumpGateRecord> recordsForSystem(SystemSymbol systemSymbol) {
    return values
        .where((record) => record.waypointSymbol.systemSymbol == systemSymbol);
  }

  /// Gets the connections for the jump gate with the given symbol.
  Set<WaypointSymbol>? connectionsForSymbol(WaypointSymbol waypointSymbol) =>
      recordForSymbol(waypointSymbol)?.connections;

  /// Gets the JumpGateRecord for the given waypoint symbol.
  JumpGateRecord? recordForSymbol(WaypointSymbol waypointSymbol) =>
      values.firstWhereOrNull(
        (record) => record.waypointSymbol == waypointSymbol,
      );

  /// Returns the age of the cache for a given waypoint.
  Duration? cacheAgeFor(
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) {
    final record = recordForSymbol(waypointSymbol);
    if (record == null) {
      return null;
    }
    return getNow().difference(record.timestamp);
  }

  /// Gets the JumpGate for the given waypoint symbol.
  Future<JumpGate> getOrFetch(
    Api api,
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    final record = recordForSymbol(waypointSymbol);
    if (record != null) {
      return record.toJumpGate();
    }
    final jumpGate = await getJumpGate(api, waypointSymbol);
    updateJumpGate(
      waypointSymbol: waypointSymbol,
      jumpGate: jumpGate,
      getNow: getNow,
    );
    return jumpGate;
  }
}