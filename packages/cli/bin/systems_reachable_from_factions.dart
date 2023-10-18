import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:collection/collection.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();
  final systemsCache = await SystemsCache.load(fs);
  final factionsApi = FactionsApi();
  final factions = await loadFactions(db, factionsApi);

  final clusterCache = SystemConnectivity.fromSystemsCache(systemsCache);

  final symbolLength = factions.map((f) => f.symbol.value.length).max;
  const systemLength = 7;
  const waypointLength = 9;
  logger.info('${'Faction'.padRight(symbolLength)} Systems Waypoints');
  for (final faction in factions) {
    final hq = faction.headquartersSymbol;
    final systemCount = clusterCache.connectedSystemCount(hq.systemSymbol);
    final waypointCount = clusterCache.connectedWaypointCount(
      systemsCache,
      hq.systemSymbol,
    );
    logger.info('${faction.symbol.value.padRight(symbolLength)} '
        '${systemCount.toString().padLeft(systemLength)} '
        '${waypointCount.toString().padLeft(waypointLength)}');
  }

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
