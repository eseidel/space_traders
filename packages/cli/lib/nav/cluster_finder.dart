import 'package:cli/cache/systems_cache.dart';

typedef _ClusterId = int;

/// Finds clusters of systems.
class ClusterFinder {
  /// Creates a new cluster finder.
  ClusterFinder(this.systemsCache);

  /// The systems cache being used by this cluster finder.
  final SystemsCache systemsCache;

  final _clusterForSystem = <String, _ClusterId>{};
  _ClusterId _nextClusterId = 0;
  final Map<_ClusterId, int> _clusterCounts = {};

  /// Returns the number of systems reachable from [systemSymbol].
  int connectedSystemCount(String systemSymbol) {
    final cluster = _clusterForSystem[systemSymbol];
    if (cluster == null) {
      throw Exception('System $systemSymbol has no cluster');
    }
    return _clusterCounts[cluster]!;
  }

  /// Paints the cluster reachable from [startSystemSymbol].
  void paintCluster(String startSystemSymbol) {
    if (_clusterForSystem.containsKey(startSystemSymbol)) {
      return;
    }
    final queue = [startSystemSymbol];
    final cluster = _nextClusterId++;
    var clusterCount = 0;

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
      clusterCount++;
      final connected = systemsCache.connectedSystems(systemSymbol);
      queue.addAll(connected.map((s) => s.symbol));
    }
    _clusterCounts[cluster] = clusterCount;
  }
}
