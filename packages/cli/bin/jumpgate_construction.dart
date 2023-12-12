import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final systemsCache = SystemsCache.load(fs)!;

  final constructionCache = ConstructionCache.load(fs);
  final jumpGateCache = JumpGateCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionCache);

  // Find all reachable jumpgates that are under construction.
  final systemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol);
  final jumpGates = systemSymbols
      .expand(systemsCache.waypointsInSystem)
      .where((w) => w.isJumpGate)
      .toList();
  final underConstruction = jumpGates
      .where(
        (w) => constructionCache.isUnderConstruction(w.waypointSymbol) ?? false,
      )
      .toList();

  logger.info(
    '${underConstruction.length} reachable jumpgates under construction:',
  );
  for (final waypoint in underConstruction) {
    logger.info(waypoint.waypointSymbol.sectorLocalName);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
