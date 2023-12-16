import 'package:cli/cache/caches.dart';
import 'package:cli/cache/json_list_store.dart';
import 'package:cli/logger.dart';
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
    this.isBroken = false,
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
      isBroken: json['isBroken'] as bool? ?? false,
    );
  }

  /// The waypoint symbol.
  final WaypointSymbol waypointSymbol;

  /// The last time this record was updated.
  final DateTime timestamp;

  /// The connections for this jump gate.
  final Set<WaypointSymbol> connections;

  /// Record that a jump gate is broken (bug in the game).
  final bool isBroken;

  /// The connected system symbols.
  Set<SystemSymbol> get connectedSystemSymbols =>
      connections.map((e) => e.systemSymbol).toSet();

  /// Converts this object to JumpGate model object.
  JumpGate toJumpGate() => JumpGate(
        symbol: waypointSymbol.waypoint,
        connections: connections.map((e) => e.toString()).sorted(),
      );

  @override
  List<Object?> get props => [waypointSymbol, timestamp, connections, isBroken];

  /// Converts this object to a JSON encodable object.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestamp': timestamp.toIso8601String(),
        'connections': connections.map((e) => e.toJson()).sorted(),
        'waypointSymbol': waypointSymbol.toJson(),
        'isBroken': isBroken,
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
  void updateJumpGate(JumpGateRecord jumpGateRecord) {
    final index = records.indexWhere(
      (record) => record.waypointSymbol == jumpGateRecord.waypointSymbol,
    );

    if (index >= 0) {
      records[index] = jumpGateRecord;
    } else {
      records.add(jumpGateRecord);
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

  /// Marks a jump gate as broken.
  void markBroken(WaypointSymbol waypointSymbol) {
    final record = recordForSymbol(waypointSymbol);
    if (record == null) {
      logger.err('Unable to mark broken: $waypointSymbol');
      return;
    }
    updateJumpGate(
      JumpGateRecord(
        connections: record.connections,
        timestamp: record.timestamp,
        waypointSymbol: record.waypointSymbol,
        isBroken: true,
      ),
    );
  }

  /// Gets the JumpGate for the given waypoint symbol.
  Future<JumpGateRecord> getOrFetch(
    Api api,
    WaypointSymbol waypointSymbol, {
    DateTime Function() getNow = defaultGetNow,
  }) async {
    final cached = recordForSymbol(waypointSymbol);
    if (cached != null) {
      return cached;
    }
    final jumpGate = await getJumpGate(api, waypointSymbol);

    final record =
        JumpGateRecord.fromJumpGate(waypointSymbol, jumpGate, getNow());
    updateJumpGate(record);
    return record;
  }
}
