import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:cli/printing.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final systemsCache = SystemsCache.load(fs)!;
  final jumpGateSymbol = systemsCache
      .waypointsInSystem(startSystemSymbol)
      .firstWhere((w) => w.isJumpGate)
      .waypointSymbol;
  final staticCaches = StaticCaches.load(fs);

  final chartingCache = ChartingCache.load(fs, staticCaches.waypointTraits);
  final constructionCache = ConstructionCache.load(fs);
  final waypointCache =
      WaypointCache(api, systemsCache, chartingCache, constructionCache);
  final jumpGateCache = JumpGateCache.load(fs);
  final jumpGate = await jumpGateCache.getOrFetch(api, jumpGateSymbol);

  Future<String> statusString(WaypointSymbol jumpGateSymbol) async {
    final isUnderConstrustion =
        await waypointCache.isUnderConstruction(jumpGateSymbol);

    if (isUnderConstrustion) {
      final construction = constructionCache[jumpGateSymbol];
      final progress = describeConstructionProgress(construction);
      return 'under construction ($progress)';
    }
    return 'ready';
  }

  logger.info('$jumpGateSymbol: ${await statusString(jumpGateSymbol)}');
  for (final connection in jumpGate.connections) {
    final status = await statusString(connection);
    logger.info('  ${connection.sectorLocalName.padRight(9)} $status');
  }

  // Required or main() will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
