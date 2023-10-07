import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:db/db.dart';
import 'package:types/api.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final systemsCache = await SystemsCache.load(fs);
  final factionsApi = FactionsApi();
  final factions = await loadFactions(db, factionsApi);

  final clusterCache = SystemConnectivity.fromSystemsCache(systemsCache);

  for (final faction in factions) {
    final hq = faction.headquartersSymbol;
    final reachable = clusterCache.connectedSystemCount(hq.systemSymbol);
    logger.info('${faction.symbol}: $reachable');
  }

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
