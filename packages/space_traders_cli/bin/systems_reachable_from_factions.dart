import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/logger.dart';
import 'package:space_traders_cli/net/queries.dart';

class ClusterFinder {
  ClusterFinder(this.systemsCache);

  final SystemsCache systemsCache;

  final clusterForSystem = <String, int>{};
  int _nextClusterId = 0;
  final Map<int, int> _clusterCounts = {};

  int connectedSystemCount(String systemSymbol) {
    final cluster = clusterForSystem[systemSymbol];
    if (cluster == null) {
      throw Exception('System $systemSymbol has no cluster');
    }
    return _clusterCounts[cluster]!;
  }

  void paintCluster(String startSystemSymbol) {
    if (clusterForSystem.containsKey(startSystemSymbol)) {
      return;
    }
    final queue = [startSystemSymbol];
    final cluster = _nextClusterId++;
    var clusterCount = 1;

    while (queue.isNotEmpty) {
      final systemSymbol = queue.removeAt(0);
      final maybeCluster = clusterForSystem[systemSymbol];
      if (maybeCluster != null) {
        if (maybeCluster != cluster) {
          throw Exception(
            'System $systemSymbol is in cluster $maybeCluster and $cluster',
          );
        }
        continue;
      }
      clusterForSystem[systemSymbol] = cluster;
      clusterCount++;
      final connected = systemsCache.connectedSystems(systemSymbol);
      queue.addAll(connected.map((s) => s.symbol));
    }
    _clusterCounts[cluster] = clusterCount;
  }
}

Stream<Faction> _getAllFactionsUnauthenticated() {
  final factionsApi = FactionsApi();
  return fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response!.data, response.meta);
  });
}

Future<void> cliMain() async {
// Load up all the factions HQs.
// Find the number of systems reachable from each HQ.
// Might be easier to do a reachability analysis for all systems and cache?

  const fs = LocalFileSystem();
  final systemsCache = await SystemsCache.load(fs);

  final factions = await _getAllFactionsUnauthenticated().toList();
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.symbol.value: faction.headquarters
  };

  final startingSystems =
      hqByFaction.values.map((w) => parseWaypointString(w).system).toList();
  final clusterFinder = ClusterFinder(systemsCache);
  for (final systemSymbol in startingSystems) {
    clusterFinder.paintCluster(systemSymbol);
  }

  for (final faction in hqByFaction.keys) {
    final hq = hqByFaction[faction]!;
    final reachable = clusterFinder.connectedSystemCount(
      parseWaypointString(hq).system,
    );
    logger.info('$faction: $reachable');
  }

  // Find all systems with jumpgates.
  // Starting at each HQ, give each system a cluster number.
  // Start from each HQ, and do a breadth-first search to find all reachable
  // systems, and assign them the same cluster number.
}

void main() async {
  await runScoped(cliMain, values: {loggerRef});
}
