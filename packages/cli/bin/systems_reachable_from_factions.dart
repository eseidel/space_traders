import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/logger.dart';
import 'package:cli/nav/system_connectivity.dart';
import 'package:file/file.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = await SystemsCache.load(fs);
  final factionCache = await FactionCache.loadUnauthenticated(fs);

  final factions = factionCache.factions;
  final hqByFaction = <String, String>{
    for (final faction in factions) faction.symbol.value: faction.headquarters
  };

  final clusterCache = SystemConnectivity.fromSystemsCache(systemsCache);
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
