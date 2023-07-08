import 'package:cli/cache/systems_cache.dart';

typedef _ClusterId = int;

/// Finds clusters of systems.
class _ClusterFinder {
  /// Creates a new cluster finder.
  _ClusterFinder(this.systemsCache);

  /// The systems cache being used by this cluster finder.
  final SystemsCache systemsCache;

  final _clusterForSystem = <String, _ClusterId>{};
  _ClusterId _nextClusterId = 0;

  /// Returns a Map from System symbol to cluster id.
  /// Cluster ids may not be stable, depending on what order the input
  /// systems were processed.
  Map<String, int> get clusterBySystemSymbol => _clusterForSystem;

  /// Paints the cluster reachable from [startSystemSymbol].
  void paintCluster(String startSystemSymbol) {
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
      queue.addAll(connected.map((s) => s.symbol));
    }
  }
}

Map<String, int> _findClusters(SystemsCache systemsCache) {
  final clusterFinder = _ClusterFinder(systemsCache);
  for (final system in systemsCache.systems) {
    clusterFinder.paintCluster(system.symbol);
  }
  return clusterFinder.clusterBySystemSymbol;
}

/// Holds the results from finding clusters of systems on the jumpgate
/// networks.
class SystemConnectivity {
  /// Creates a new SystemConnectivity.
  SystemConnectivity(Map<String, int> clusterBySystemSymbol)
      : _clusterBySystemSymbol = clusterBySystemSymbol;

  /// Creates a new SystemConnectivity from the systemsCache.
  factory SystemConnectivity.fromSystemsCache(SystemsCache systemsCache) {
    return SystemConnectivity(_findClusters(systemsCache));
  }

  final Map<String, int> _clusterBySystemSymbol;

  /// Returns the number of systems reachable from [systemSymbol].
  int connectedSystemCount(String systemSymbol) {
    final systemClusterId = _clusterBySystemSymbol[systemSymbol];
    if (systemClusterId == null) {
      throw ArgumentError('System $systemSymbol has no cluster');
    }
    return _clusterBySystemSymbol.values
        .where((v) => v == systemClusterId)
        .length;
  }

  /// Returns true if there exists a path in the jumpgate network between
  /// [startSystemSymbol] and [endSystemSymbol]
  bool canJumpBetween({
    required String startSystemSymbol,
    required String endSystemSymbol,
  }) {
    final startCluster = _clusterBySystemSymbol[startSystemSymbol];
    final endCluster = _clusterBySystemSymbol[endSystemSymbol];
    return startCluster == endCluster;
  }
}
