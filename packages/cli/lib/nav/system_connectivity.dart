import 'package:cli/cache/systems_cache.dart';
import 'package:types/types.dart';

typedef _ClusterId = int;

/// Finds clusters of systems.
class _ClusterFinder {
  /// Creates a new cluster finder.
  _ClusterFinder(this.systemsCache);

  /// The systems cache being used by this cluster finder.
  final SystemsCache systemsCache;

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
    final queue = [startSystemSymbol];
    final cluster = _nextClusterId++;

    while (queue.isNotEmpty) {
      final systemSymbol = queue.removeAt(0);
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
      final connected = systemsCache.connectedSystems(systemSymbol);
      queue.addAll(connected.map((s) => s.systemSymbol));
    }
  }
}

Map<SystemSymbol, int> _findClusters(SystemsCache systemsCache) {
  final clusterFinder = _ClusterFinder(systemsCache);
  for (final system in systemsCache.systems) {
    clusterFinder.paintCluster(system.systemSymbol);
  }
  return clusterFinder.clusterBySystemSymbol;
}

/// Holds the results from finding clusters of systems on the jumpgate
/// networks.
class SystemConnectivity {
  /// Creates a new SystemConnectivity.
  SystemConnectivity(Map<SystemSymbol, int> clusterBySystemSymbol)
      : _clusterBySystemSymbol = clusterBySystemSymbol;

  /// Creates a new SystemConnectivity from the systemsCache.
  factory SystemConnectivity.fromSystemsCache(SystemsCache systemsCache) {
    return SystemConnectivity(_findClusters(systemsCache));
  }

  final Map<SystemSymbol, int> _clusterBySystemSymbol;

  /// Returns the number of systems reachable from [systemSymbol].
  int connectedSystemCount(SystemSymbol systemSymbol) {
    final systemClusterId = _clusterBySystemSymbol[systemSymbol];
    if (systemClusterId == null) {
      throw ArgumentError('System $systemSymbol has no cluster');
    }
    return _clusterBySystemSymbol.values
        .where((v) => v == systemClusterId)
        .length;
  }

  /// Returns the cluster id for the given system.
  int clusterIdForSystem(SystemSymbol systemSymbol) =>
      _clusterBySystemSymbol[systemSymbol]!;

  /// Returns all the systemSymbols in a given cluster. This is most useful when
  /// looking up a cluster for a specific system first, then you can use this
  /// method to find all the systems in that cluster.
  Iterable<SystemSymbol> systemSymbolsByClusterId(int clusterId) =>
      _clusterBySystemSymbol.entries
          .where((e) => e.value == clusterId)
          .map((e) => e.key);

  /// Returns true if there exists a path in the jumpgate network between
  /// [startSymbol] and [endSymbol]
  bool canJumpBetweenSystemSymbols(
    SystemSymbol startSymbol,
    SystemSymbol endSymbol,
  ) {
    final startCluster = _clusterBySystemSymbol[startSymbol];
    final endCluster = _clusterBySystemSymbol[endSymbol];
    return startCluster == endCluster;
  }
}
