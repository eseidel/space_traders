import 'package:cli/api.dart';
import 'package:cli/cache/faction_cache.dart';
import 'package:cli/cache/systems_cache.dart';
import 'package:cli/cli.dart';
import 'package:cli/nav/system_connectivity.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final systemsCache = await SystemsCache.load(fs);
  final factionCache = await FactionCache.loadUnauthenticated(fs);

  final factions = factionCache.factions;

  final clusterCache = SystemConnectivity.fromSystemsCache(systemsCache);
  for (final faction in factions) {
    final hq = faction.headquartersSymbol;
    final reachable = clusterCache.connectedSystemCount(hq.systemSymbol);
    logger.info('${faction.symbol}: $reachable');
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
