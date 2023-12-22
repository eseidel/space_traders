import 'package:cli/cache/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, ArgResults argResults) async {
  final db = await defaultDatabase();

  final SystemSymbol startSystemSymbol;
  if (argResults.rest.isNotEmpty) {
    startSystemSymbol = SystemSymbol.fromString(argResults.rest.first);
  } else {
    final agentCache = AgentCache.load(fs)!;
    startSystemSymbol = agentCache.headquartersSystemSymbol;
  }

  final systemsCache = SystemsCache.load(fs)!;

  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final jumpGateCache = JumpGateCache.load(fs);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateCache, constructionSnapshot);

  // Find all reachable jumpgates that are under construction.
  final systemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol);
  final jumpGates = systemSymbols
      .expand(systemsCache.waypointsInSystem)
      .where((w) => w.isJumpGate)
      .map((w) => w.waypointSymbol);
  final underConstruction = jumpGates
      .where((s) => constructionSnapshot.isUnderConstruction(s) ?? false);
  logger.info(
    '${underConstruction.length} reachable jumpgates under construction:',
  );
  for (final waypointSymbol in underConstruction) {
    logger.info(waypointSymbol.sectorLocalName);
  }
}

void main(List<String> args) async {
  await runOffline(args, command);
}
