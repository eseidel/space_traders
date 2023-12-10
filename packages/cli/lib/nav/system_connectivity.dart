import 'package:cli/cache/construction_cache.dart';
import 'package:cli/cache/jump_gate_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:types/types.dart';

typedef _ClusterId = int;

/// Finds clusters of systems.
class _ClusterFinder {
  /// Creates a new cluster finder.
  _ClusterFinder(this.directConnections);

  final Map<SystemSymbol, Set<SystemSymbol>> directConnections;

  final _clusterForSystem = <SystemSymbol, _ClusterId>{};
  _ClusterId _nextClusterId = 0;

  /// Returns a Map from System symbol to cluster id.
  /// Cluster ids may not be stable, depending on what order the input
  /// systems were processed.
  Map<SystemSymbol, int> get clusterBySystemSymbol => _clusterForSystem;

  /// Paints the cluster reachable from [startSystemSymbol].
  void paintCluster(SystemSymbol startSystemSymbol) {
    if (_clusterForSystem.containsKey(startSystemSymbol)) {
      return;
    }
    final queue = {startSystemSymbol};
    final cluster = _nextClusterId++;

    while (queue.isNotEmpty) {
      final systemSymbol = queue.first;
      queue.remove(systemSymbol);
      final maybeCluster = _clusterForSystem[systemSymbol];
      if (maybeCluster != null) {
        if (maybeCluster != cluster) {
          throw Exception(
            'System $systemSymbol is in cluster $maybeCluster and $cluster',
          );
        }
        continue;
      }
      _clusterForSystem[systemSymbol] = cluster;
      final connected = directConnections[systemSymbol] ?? {};
      for (final symbol in connected) {
        if (!_clusterForSystem.containsKey(symbol)) {
          queue.add(symbol);
        }
      }
    }
  }
}

class _Clusters {
  _Clusters(this._clusterBySystemSymbol);

  factory _Clusters.fromConnections(_Connections connections) {
    final clusterFinder = _ClusterFinder(connections.systems);
    for (final systemSymbol in connections.systems.keys) {
      clusterFinder.paintCluster(systemSymbol);
    }
    return _Clusters(clusterFinder.clusterBySystemSymbol);
  }

  final Map<SystemSymbol, int> _clusterBySystemSymbol;
  final Map<int, int> _systemCountByClusterId = {};

  /// Returns the number of systems reachable from [systemSymbol].
  int connectedSystemCount(SystemSymbol systemSymbol) {
    final systemClusterId = _clusterBySystemSymbol[systemSymbol];
    if (systemClusterId == null) {
      throw ArgumentError('System $systemSymbol has no cluster');
    }
    if (!_systemCountByClusterId.containsKey(systemClusterId)) {
      _systemCountByClusterId[systemClusterId] = _clusterBySystemSymbol.values
          .where((v) => v == systemClusterId)
          .length;
    }
    return _systemCountByClusterId[systemClusterId]!;
  }

  /// Returns the cluster id for the given system.
  int? clusterIdForSystem(SystemSymbol systemSymbol) =>
      _clusterBySystemSymbol[systemSymbol];

  /// Returns all the systemSymbols in a given cluster. This is most useful when
  /// looking up a cluster for a specific system first, then you can use this
  /// method to find all the systems in that cluster.
  Iterable<SystemSymbol> systemSymbolsByClusterId(int clusterId) =>
      _clusterBySystemSymbol.entries
          .where((e) => e.value == clusterId)
          .map((e) => e.key);
}

// Used for converting a partial graph to a fully connected graph.
// Makes it easy to write tests listing just single direction connections.
// Map<SystemSymbol, Set<SystemSymbol>> _fullyConnect(
//   Map<SystemSymbol, Set<SystemSymbol>> partial,
// ) {
//   final fullyConnected = <SystemSymbol, Set<SystemSymbol>>{};
//   for (final systemSymbol in partial.keys) {
//     final connectedSymbols = partial[systemSymbol] ?? {};
//     for (final connectedSymbol in connectedSymbols) {
//       fullyConnected.putIfAbsent(systemSymbol,
//        () => {}).add(connectedSymbol);
//       fullyConnected.putIfAbsent(connectedSymbol,
//        () => {}).add(systemSymbol);
//     }
//   }
//   return fullyConnected;
// }

// This could be simplified by storing waypoints instead.
class _Connections {
  _Connections.fromPartial(
    Map<WaypointSymbol, Set<WaypointSymbol>> partialConnections,
  ) {
    for (final from in partialConnections.keys) {
      final fromSystem = from.systemSymbol;
      for (final to in partialConnections[from]!) {
        final toSystem = to.systemSymbol;
        systems.putIfAbsent(fromSystem, () => {}).add(toSystem);
        systems.putIfAbsent(toSystem, () => {}).add(fromSystem);
      }
    }
  }

  _Connections.fromCaches(
    JumpGateCache jumpGateCache,
    ConstructionCache constructionCache,
  ) {
    // JumpGateCache caches responses from the server.  We may not yet have
    // cached both sides of a jump gate, so this fills in the gaps.
    for (final record in jumpGateCache.values) {
      final from = record.waypointSymbol;
      final fromUnderConstruction = constructionCache.isUnderConstruction(from);
      // If we don't know or it's not complete, we can't jump.
      if (fromUnderConstruction == null || fromUnderConstruction == true) {
        continue;
      }
      final fromSystem = from.systemSymbol;
      for (final to in record.connections) {
        final toUnderConstruction = constructionCache.isUnderConstruction(to);
        // If we don't know or it's not complete, we can't jump.
        if (toUnderConstruction == null || toUnderConstruction == true) {
          continue;
        }
        final toSystem = to.systemSymbol;
        systems.putIfAbsent(fromSystem, () => {}).add(toSystem);
        systems.putIfAbsent(toSystem, () => {}).add(fromSystem);
      }
    }
  }

  /// Maps a waypoint to the set of waypoints it has direct connections to.
  // final Map<WaypointSymbol, Set<WaypointSymbol>> waypoints = {};
  // Maps a system to the set of systems it has direct connections to.
  final Map<SystemSymbol, Set<SystemSymbol>> systems = {};
}

/// Holds connectivity information between systems.
class SystemConnectivity {
  /// Creates a new SystemConnectivity.
  SystemConnectivity._(this._connections)
      : _clusters = _Clusters.fromConnections(_connections);

  /// Creates a new SystemConnectivity from the given connections.
  @visibleForTesting
  factory SystemConnectivity.test(
    Map<WaypointSymbol, Set<WaypointSymbol>> partial,
  ) {
    return SystemConnectivity._(_Connections.fromPartial(partial));
  }

  /// Creates a new SystemConnectivity from the systemsCache.
  factory SystemConnectivity.fromJumpGates(
    JumpGateCache jumpGates,
    ConstructionCache construction,
  ) {
    final connections = _Connections.fromCaches(jumpGates, construction);
    return SystemConnectivity._(connections);
  }

  _Connections _connections;
  _Clusters _clusters;

  /// Returns the number of systems reachable from [systemSymbol].
  int connectedSystemCount(SystemSymbol systemSymbol) =>
      _clusters.connectedSystemCount(systemSymbol);

  /// Returns the cluster id for the given system.
  int? clusterIdForSystem(SystemSymbol systemSymbol) =>
      _clusters.clusterIdForSystem(systemSymbol);

  /// Returns all the systemSymbols in a given cluster. This is most useful when
  /// looking up a cluster for a specific system first, then you can use this
  /// method to find all the systems in that cluster.
  Iterable<SystemSymbol> systemSymbolsByClusterId(int clusterId) =>
      _clusters.systemSymbolsByClusterId(clusterId);

  /// Returns a list of all systems known to be reachable from [systemSymbol].
  Iterable<SystemSymbol> systemsReachableFrom(SystemSymbol systemSymbol) {
    final clusterId = clusterIdForSystem(systemSymbol);
    if (clusterId == null) {
      return [];
    }
    return systemSymbolsByClusterId(clusterId);
  }

  /// Returns systems that are directly connected to [systemSymbol].
  Set<SystemSymbol> directlyConnectedSystemSymbols(SystemSymbol systemSymbol) =>
      _connections.systems[systemSymbol] ?? {};

  /// Returns true if there exists a direct jump between [start] and [end].
  bool existsDirectJumpBetween(SystemSymbol start, SystemSymbol end) {
    return _connections.systems[start]?.contains(end) ?? false;
  }

  /// Returns true if there exists a path in the jumpgate network between
  /// [start] and [end] or they are the same.
  bool existsJumpPathBetween(SystemSymbol start, SystemSymbol end) {
    // Even if we don't have a cluster for the start or end, we can still
    // check if they are the same.
    if (start == end) {
      return true;
    }
    final startCluster = _clusters._clusterBySystemSymbol[start];
    final endCluster = _clusters._clusterBySystemSymbol[end];
    return startCluster != null && startCluster == endCluster;
  }

  /// Yields a stream of system symbols that are within n jumps of the system.
  /// The system itself is included in the stream with distance 0.
  /// The stream is roughly ordered by distance from the start.
  Iterable<(SystemSymbol systemSymbol, int jumps)> systemSymbolsInJumpRadius(
    SystemsCache systemsCache, {
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
        if (jumpsLeft <= 0) {
          continue;
        }
        // Don't add systems we've already examined or are already in the
        // list to examine next.
        final connectedSystems = directlyConnectedSystemSymbols(jumpFrom)
            .where(
              (s) =>
                  !systemsExamined.contains(s) &&
                  !currentSystemsToJumpFrom.contains(s) &&
                  !oneJumpFurther.contains(s),
            )
            .map((s) => systemsCache[s]);
        final jumpFromSystem = systemsCache[jumpFrom];
        final sortedSystems =
            connectedSystems.sortedBy<num>((s) => s.distanceTo(jumpFromSystem));
        for (final connectedSystem in sortedSystems) {
          oneJumpFurther.add(connectedSystem.systemSymbol);
        }
      }
      currentSystemsToJumpFrom.addAll(oneJumpFurther);
      oneJumpFurther.clear();
      jumpsLeft--;
    }
  }
}
