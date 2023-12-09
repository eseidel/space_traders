import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  // Load up the jump gate for the main system.
  // List its connections.
  // Check if each is constructed.
  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final agentCache = AgentCache.load(fs)!;
  final hqSystem = agentCache.headquartersSystemSymbol;
  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateSymbol = systemsCache
      .waypointsInSystem(hqSystem)
      .firstWhere((w) => w.isJumpGate)
      .waypointSymbol;
  final staticCaches = StaticCaches.load(fs);

  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);
  final constructionCache = ConstructionCache.load(fs);
  final waypointCache =
      WaypointCache(api, systemsCache, chartingCache, constructionCache);
  final jumpGateCache = JumpGateCache.load(fs);
  final jumpGate = await jumpGateCache.getOrFetch(api, jumpGateSymbol);
  logger.info('$jumpGateSymbol:');
  for (final connection in jumpGate.connections) {
    final waypoint = await waypointCache.waypoint(connection);
    final status =
        waypoint.isUnderConstruction ? 'under construction' : 'ready';
    logger.info('  ${connection.sectorLocalName.padRight(9)} $status');
  }

  // Required or main() will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
