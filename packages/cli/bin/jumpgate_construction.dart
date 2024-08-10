import 'package:cli/caches.dart';
import 'package:cli/cli.dart';

Future<void> command(FileSystem fs, Database db, ArgResults argResults) async {
  final startSystemSymbol =
      await startSystemFromArg(db, argResults.rest.firstOrNull);

  final systemsCache = SystemsCache.load(fs);

  // Can't use loadSystemConnectivity because need constructionSnapshot later.
  final constructionSnapshot = await ConstructionSnapshot.load(db);
  final jumpGateSnapshot = await JumpGateSnapshot.load(db);
  final systemConnectivity =
      SystemConnectivity.fromJumpGates(jumpGateSnapshot, constructionSnapshot);

  // Find all reachable jumpgates that are under construction.
  final systemSymbols =
      systemConnectivity.systemsReachableFrom(startSystemSymbol);
  final jumpGates = systemSymbols
      .expand(systemsCache.waypointsInSystem)
      .where((w) => w.isJumpGate)
      .map((w) => w.symbol);
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
