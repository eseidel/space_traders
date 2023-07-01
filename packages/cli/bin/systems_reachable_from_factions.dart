import 'package:cli/api.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/cluster_finder.dart';
import 'package:cli/net/queries.dart';
import 'package:file/file.dart';

Stream<Faction> _getAllFactionsUnauthenticated() {
  final factionsApi = FactionsApi();
  return fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response!.data, response.meta);
  });
}

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = await SystemsCache.load(fs);

  final factions = await _getAllFactionsUnauthenticated().toList();
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.symbol.value: faction.headquarters
  };

  // Starting at each HQ, give each system a cluster number.
  // Start from each HQ, and do a breadth-first search to find all reachable
  // systems, and assign them the same cluster number.
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
}

void main(List<String> args) async {
  await runOffline(args, command);
}
