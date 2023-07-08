import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/system_reachability.dart';
import 'package:cli/net/queries.dart';
import 'package:file/file.dart';

Stream<Faction> _getAllFactionsUnauthenticated() {
  final factionsApi = FactionsApi();
  return fetchAllPages(factionsApi, (factionsApi, page) async {
    final response = await factionsApi.getFactions(page: page);
    return (response!.data, response.meta);
  });
}

Future<FactionCache> _loadFactionCache(FileSystem fs) async {
  final cache = FactionCache.loadFromCache(fs);
  if (cache != null) {
    return cache;
  }
  final factions = await _getAllFactionsUnauthenticated().toList();
  return FactionCache(factions, fs: fs);
}

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = await SystemsCache.load(fs);
  final factionCache = await _loadFactionCache(fs);

  final factions = factionCache.factions;
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.symbol.value: faction.headquarters
  };

  final clusterCache = SystemReachability.fromSystemsCache(systemsCache);
  for (final faction in hqByFaction.keys) {
    final hq = hqByFaction[faction]!;
    final reachable = clusterCache.connectedSystemCount(
      parseWaypointString(hq).system,
    );
    logger.info('$faction: $reachable');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
