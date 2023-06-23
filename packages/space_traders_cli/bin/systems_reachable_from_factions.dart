import 'package:file/local.dart';
import 'package:scoped/scoped.dart';
import 'package:space_traders_cli/api.dart';
import 'package:space_traders_cli/cache/systems_cache.dart';
import 'package:space_traders_cli/logger.dart';

final hqByFaction = {
  'Cosmic Engineers': 'X1-ZT91-90060F',
  'Voidfarers': 'X1-QV16-48270X',
  'Galactic Alliance': 'X1-GX61-52060A',
  'Quantum Federation': 'X1-JY4-10620Z',
  'Stellar Dominion': 'X1-MZ97-82310B',
  'Astro-Salvage Alliance': 'X1-HV92-92380A',
  'Seventh Space Corsairs': 'X1-XR77-94090F',
  'Obsidian Syndicate': 'X1-GX98-61300D',
  'Aegis Collective': 'X1-FD34-85450C',
  'United Independent Settlements': 'X1-MH43-62860F',
  'Solitary Systems Alliance': 'X1-RS97-03910B',
  'Cobalt Traders Alliance': 'X1-VG20-48250F',
  'Omega Star Network': 'X1-YR16-63760F',
  'Echo Technological Conclave': 'X1-QN84-21330Z',
  'Lords of the Void': 'X1-QM47-80470D',
  'Cult of the Machine': 'X1-UV4-35890X',
  'Ancient Guardians': 'X1-QM50-15330F',
  'Shadow Stalkers': 'X1-XB85-02550Z',
  'Ethereal Enclave': 'X1-BK36-82930F'
};

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

Future<void> cliMain() async {
// Load up all the factions HQs.
// Find the number of systems reachable from each HQ.
// Might be easier to do a reachability analysis for all systems and cache?

  const fs = LocalFileSystem();
  final systemsCache = await SystemsCache.load(fs);

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
