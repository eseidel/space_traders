import 'package:types/types.dart';

/// `int` alias to make it easier to differentiate between cluster ids and
/// other integers.
typedef ClusterId = int;

/// Finds clusters
class ClusterFinder<Key> {
  /// Creates a new cluster finder.
  ClusterFinder(this.connections);

  /// Callback for getting connections from a key.
  final Iterable<Key> Function(Key key) connections;

  /// The cluster id for each key.
  final clusterForKey = <Key, ClusterId>{};
  ClusterId _nextClusterId = 0;

  /// Paints the cluster reachable from [start].
  void paintCluster(Key start) {
    if (clusterForKey.containsKey(start)) {
      // We've already painted this cluster.
      return;
    }
    final queue = {start};
    final cluster = _nextClusterId++;

    while (queue.isNotEmpty) {
      final next = queue.first;
      queue.remove(next);
      final maybeCluster = clusterForKey[next];
      if (maybeCluster != null) {
        if (maybeCluster != cluster) {
          throw Exception('$next is in cluster $maybeCluster and $cluster');
        }
        continue;
      }
      clusterForKey[next] = cluster;
      for (final other in connections(next)) {
        if (!clusterForKey.containsKey(other)) {
          queue.add(other);
        }
      }
    }
  }
}

/// Holds the results from a cluster search across waypoints in a system.
class WaypointConnectivity {
  /// Creates a new SystemConnectivity.
  WaypointConnectivity(Map<WaypointSymbol, ClusterId> clusterByWaypointSymbol)
    : _clusterByWaypointSymbol = clusterByWaypointSymbol;

  /// Creates a new SystemConnectivity from the systemsCache.
  factory WaypointConnectivity.fromSystemAndFuelCapacity(
    SystemsSnapshot systemsCache,
    SystemSymbol systemSymbol,
    int fuelCapacity,
  ) {
    final system = systemsCache[systemSymbol];
    final clusterFinder = ClusterFinder<WaypointSymbol>((s) {
      final start = system.waypoints.firstWhere((w) => w.symbol == s);
      return system.waypoints
          .where((w) => w.distanceTo(start) < fuelCapacity)
          .map((w) => w.symbol);
    });
    for (final waypoint in system.waypoints) {
      clusterFinder.paintCluster(waypoint.symbol);
    }
    return WaypointConnectivity(clusterFinder.clusterForKey);
  }

  final Map<WaypointSymbol, ClusterId> _clusterByWaypointSymbol;

  /// Returns the list of Waypoints in the given cluster.
  Iterable<WaypointSymbol> waypointSymbolsInCluster(ClusterId clusterId) =>
      _clusterByWaypointSymbol.entries
          .where((e) => e.value == clusterId)
          .map((e) => e.key);

  /// Returns the cluster id for the given system.
  ClusterId clusterIdForWaypoint(WaypointSymbol waypointSymbol) =>
      _clusterByWaypointSymbol[waypointSymbol]!;

  /// Returns the number of clusters.
  Set<ClusterId> get clusterIds => _clusterByWaypointSymbol.values.toSet();

  /// Returns the list of Waypoints for which there is a cruise path from
  /// [start].
  Iterable<WaypointSymbol> reachableWaypointsFrom(WaypointSymbol start) {
    return waypointSymbolsInCluster(clusterIdForWaypoint(start));
  }
}
