import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:db/db.dart';

Future<void> command(FileSystem fs, List<String> args) async {
  final db = await defaultDatabase();
  final systemsCache = await SystemsCache.load(fs);
  final factions = await loadFactions(db);

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
