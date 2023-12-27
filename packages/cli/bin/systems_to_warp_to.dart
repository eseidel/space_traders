import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';
import 'package:cli/net/auth.dart';
import 'package:collection/collection.dart';

// List the 10 nearest systems which have 10+ markets and are not reachable
// via jumpgates from HQ.  Systems worth warping to should be charted already.
Future<void> command(FileSystem fs, ArgResults argResults) async {
  const limit = 10;
  const desiredMarketCount = 10;

  final db = await defaultDatabase();
  final api = defaultApi(fs, db, getPriority: () => networkPriorityLow);

  final agentCache = AgentCache.load(fs)!;
  final startSystemSymbol = agentCache.headquartersSystemSymbol;

  final staticCaches = StaticCaches.load(fs);
  final jumpGateCache = JumpGateCache.load(fs);
  final constructionCache = ConstructionCache(db);
  final systemConnectivity = SystemConnectivity.fromJumpGates(
    jumpGateCache,
    await constructionCache.snapshot(),
  );
  final systemsCache = SystemsCache.load(fs)!;
  final chartingCache = ChartingCache(db);
  final waypointCache = WaypointCache(
    api,
    systemsCache,
    chartingCache,
    constructionCache,
    staticCaches.waypointTraits,
  );

  final reachableSystemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol).toSet();
  final startSystem = systemsCache[startSystemSymbol];

  // List out systems by warp distance from HQ.
  // Filter out ones we know how to reach.
  final systemsByDistance = systemsCache.systems
      .sortedBy<num>((s) => s.distanceTo(startSystem))
      .where((s) => !reachableSystemSymbols.contains(s.symbol));

  final systemsToWarpTo = <System>[];
  for (final system in systemsByDistance) {
    if (systemsToWarpTo.length >= limit) {
      break;
    }
    final waypoints = await waypointCache.waypointsInSystem(system.symbol);
    final marketCount = waypoints.where((w) => w.hasMarketplace).length;
    if (marketCount < desiredMarketCount) {
      continue;
    }
    systemsToWarpTo.add(system);
  }

  for (final system in systemsToWarpTo) {
    logger.info('${system.symbol}');
  }

  // Required or main will hang.
  await db.close();
}

void main(List<String> args) async {
  await runOffline(args, command);
}
