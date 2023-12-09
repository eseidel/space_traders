import 'package:cli/cache/jump_gate_cache.dart';
import 'package:cli/cache/systems_cache.dart';
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

Map<SystemSymbol, Set<SystemSymbol>> _findAllConnections(
  JumpGateCache jumpGateCache,
) {
  // JumpGateCache caches responses from the server.  We may not yet have
  // cached both sides of a jump gate, so this method fills in the gaps.
  final directConnections = <SystemSymbol, Set<SystemSymbol>>{};
  for (final record in jumpGateCache.values) {
    final systemSymbol = record.waypointSymbol.systemSymbol;

    final connected = jumpGateCache
        .recordsForSystem(systemSymbol)
        .expand<WaypointSymbol>((j) => j.connections)
        .map<SystemSymbol>((e) => e.systemSymbol)
        .toSet();
    for (final connectedSymbol in connected) {
      directConnections
          .putIfAbsent(systemSymbol, () => {})
          .add(connectedSymbol);
      directConnections
          .putIfAbsent(connectedSymbol, () => {})
          .add(systemSymbol);
    }
  }
  return directConnections;
}

Map<SystemSymbol, int> _findClusters(
  Map<SystemSymbol, Set<SystemSymbol>> directConnections,
) {
  final clusterFinder = _ClusterFinder(directConnections);
  for (final systemSymbol in directConnections.keys) {
    clusterFinder.paintCluster(systemSymbol);
  }
  return clusterFinder.clusterBySystemSymbol;
}

/// Holds the results from finding clusters of systems on the jumpgate
/// networks.
class SystemConnectivity {
  /// Creates a new SystemConnectivity.
  SystemConnectivity._(this._clusterBySystemSymbol, this._directConnections);

  /// Creates a new SystemConnectivity from the systemsCache.
  factory SystemConnectivity.fromJumpGateCache(JumpGateCache jumpGateCache) {
    final directConnections = _findAllConnections(jumpGateCache);
    return SystemConnectivity._(
      _findClusters(directConnections),
      directConnections,
    );
  }

  final Map<SystemSymbol, Set<SystemSymbol>> _directConnections;
  final Map<SystemSymbol, int> _clusterBySystemSymbol;
  final Map<int, int> _systemCountByClusterId = {};
  final Map<int, int> _waypointCountByClusterId = {};

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

  /// Returns the number of waypoints reachable from [systemSymbol].
  int connectedWaypointCount(
    SystemsCache systemsCache,
    SystemSymbol systemSymbol,
  ) {
    final systemClusterId = _clusterBySystemSymbol[systemSymbol];
    if (systemClusterId == null) {
      throw ArgumentError('System $systemSymbol has no cluster');
    }
    if (!_waypointCountByClusterId.containsKey(systemClusterId)) {
      _waypointCountByClusterId[systemClusterId] = _clusterBySystemSymbol
          .entries
          .where((e) => e.value == systemClusterId)
          .expand((e) => systemsCache.waypointsInSystem(e.key))
          .length;
    }
    return _waypointCountByClusterId[systemClusterId]!;
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

  /// Returns systems that are directly connected to [systemSymbol].
  Set<SystemSymbol> directlyConnectedSystemSymbols(SystemSymbol systemSymbol) =>
      _directConnections[systemSymbol] ?? {};

  /// Returns true if there exists a direct jump between [startSymbol] and
  /// [endSymbol].
  bool existsDirectJumpBetween(
    SystemSymbol startSymbol,
    SystemSymbol endSymbol,
  ) =>
      _directConnections[startSymbol]?.contains(endSymbol) ?? false;

  /// Returns true if there exists a path in the jumpgate network between
  /// [startSymbol] and [endSymbol]
  bool existsJumpPathBetween(
    SystemSymbol startSymbol,
    SystemSymbol endSymbol,
  ) {
    final startCluster = _clusterBySystemSymbol[startSymbol];
    final endCluster = _clusterBySystemSymbol[endSymbol];
    return startCluster != null && startCluster == endCluster;
  }
}
